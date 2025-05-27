# 寶寶生活記錄專業版（Baby Tracker）- 第一階段：Core Data 管理器

## Core Data Stack 實現

以下是 Core Data 管理器的實現，用於處理數據的持久化存儲和檢索。

```swift
import CoreData
import Combine

/// Core Data 管理器，負責處理所有 Core Data 相關操作
class CoreDataManager {
    
    // MARK: - Singleton
    
    /// 共享實例
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    
    /// 持久化容器
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BabyTracker")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // 處理錯誤情況
                fatalError("無法加載 Core Data 存儲: \(error), \(error.userInfo)")
            }
        }
        
        // 啟用自動合併策略
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    /// 主要視圖上下文
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// 創建後台上下文
    func createBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - CRUD Operations
    
    /// 保存視圖上下文中的更改
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("無法保存上下文: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// 在後台上下文中執行操作
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = createBackgroundContext()
        context.perform {
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nsError = error as NSError
                    print("無法保存後台上下文: \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
    
    /// 獲取實體的所有對象
    func fetchAll<T: NSManagedObject>(_ entityType: T.Type, sortDescriptors: [NSSortDescriptor]? = nil, predicate: NSPredicate? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("獲取數據失敗: \(error)")
            return []
        }
    }
    
    /// 獲取實體的對象數量
    func count<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("計數失敗: \(error)")
            return 0
        }
    }
    
    /// 刪除對象
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        saveContext()
    }
    
    /// 刪除多個對象
    func deleteMultiple(_ objects: [NSManagedObject]) {
        for object in objects {
            viewContext.delete(object)
        }
        saveContext()
    }
    
    /// 刪除實體的所有對象
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: String(describing: entityType))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            saveContext()
        } catch {
            print("刪除所有數據失敗: \(error)")
        }
    }
}

// MARK: - 實體擴展

/// Baby 實體擴展
extension Baby {
    /// 創建新的 Baby 實例
    static func create(name: String, birthDate: Date, gender: String, in context: NSManagedObjectContext) -> Baby {
        let baby = Baby(context: context)
        baby.id = UUID()
        baby.name = name
        baby.birthDate = birthDate
        baby.gender = gender
        baby.createdAt = Date()
        baby.updatedAt = Date()
        return baby
    }
}

/// SleepRecord 實體擴展
extension SleepRecord {
    /// 創建新的 SleepRecord 實例
    static func create(baby: Baby, startTime: Date, in context: NSManagedObjectContext) -> SleepRecord {
        let sleepRecord = SleepRecord(context: context)
        sleepRecord.id = UUID()
        sleepRecord.baby = baby
        sleepRecord.startTime = startTime
        sleepRecord.createdAt = Date()
        sleepRecord.updatedAt = Date()
        return sleepRecord
    }
    
    /// 結束睡眠記錄
    func end(at endTime: Date, quality: Int16? = nil, notes: String? = nil) {
        self.endTime = endTime
        self.quality = quality ?? 0
        self.notes = notes
        
        // 計算持續時間（分鐘）
        if let start = self.startTime {
            self.duration = endTime.timeIntervalSince(start) / 60
        }
        
        self.updatedAt = Date()
    }
}

/// EnvironmentFactor 實體擴展
extension EnvironmentFactor {
    /// 創建新的 EnvironmentFactor 實例
    static func create(sleepRecord: SleepRecord, type: String, value: String, in context: NSManagedObjectContext) -> EnvironmentFactor {
        let factor = EnvironmentFactor(context: context)
        factor.id = UUID()
        factor.sleepRecord = sleepRecord
        factor.type = type
        factor.value = value
        factor.timestamp = Date()
        return factor
    }
}

/// SleepInterruption 實體擴展
extension SleepInterruption {
    /// 創建新的 SleepInterruption 實例
    static func create(sleepRecord: SleepRecord, startTime: Date, endTime: Date, reason: String? = nil, in context: NSManagedObjectContext) -> SleepInterruption {
        let interruption = SleepInterruption(context: context)
        interruption.id = UUID()
        interruption.sleepRecord = sleepRecord
        interruption.startTime = startTime
        interruption.endTime = endTime
        interruption.reason = reason
        
        // 計算持續時間（分鐘）
        interruption.duration = endTime.timeIntervalSince(startTime) / 60
        
        // 更新睡眠記錄的中斷統計
        sleepRecord.interruptionCount += 1
        sleepRecord.totalInterruptionTime += interruption.duration
        
        return interruption
    }
}
```

## 數據存取層（Repositories）

以下是數據存取層的實現，用於提供對 Core Data 實體的訪問。

### BabyRepository

```swift
import CoreData
import Combine

/// 寶寶數據存取層
class BabyRepository {
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }
    
    /// 獲取所有寶寶
    func getAllBabies() -> [Baby] {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return coreDataManager.fetchAll(Baby.self, sortDescriptors: sortDescriptors)
    }
    
    /// 根據 ID 獲取寶寶
    func getBaby(byId id: UUID) -> Baby? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let babies = coreDataManager.fetchAll(Baby.self, predicate: predicate)
        return babies.first
    }
    
    /// 創建新寶寶
    func createBaby(name: String, birthDate: Date, gender: String) -> Baby {
        let baby = Baby.create(name: name, birthDate: birthDate, gender: gender, in: coreDataManager.viewContext)
        coreDataManager.saveContext()
        return baby
    }
    
    /// 更新寶寶信息
    func updateBaby(baby: Baby, name: String? = nil, birthDate: Date? = nil, gender: String? = nil, developmentStage: String? = nil, notes: String? = nil) {
        if let name = name {
            baby.name = name
        }
        
        if let birthDate = birthDate {
            baby.birthDate = birthDate
        }
        
        if let gender = gender {
            baby.gender = gender
        }
        
        if let developmentStage = developmentStage {
            baby.developmentStage = developmentStage
        }
        
        if let notes = notes {
            baby.notes = notes
        }
        
        baby.updatedAt = Date()
        coreDataManager.saveContext()
    }
    
    /// 刪除寶寶
    func deleteBaby(_ baby: Baby) {
        coreDataManager.delete(baby)
    }
    
    /// 獲取寶寶數量
    func getBabyCount() -> Int {
        return coreDataManager.count(Baby.self)
    }
}
```

### SleepRepository

```swift
import CoreData
import Combine

/// 睡眠記錄數據存取層
class SleepRepository {
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }
    
    /// 獲取寶寶的所有睡眠記錄
    func getSleepRecords(forBaby baby: Baby, startDate: Date? = nil, endDate: Date? = nil) -> [SleepRecord] {
        var predicates = [NSPredicate(format: "baby == %@", baby)]
        
        if let startDate = startDate {
            predicates.append(NSPredicate(format: "startTime >= %@", startDate as NSDate))
        }
        
        if let endDate = endDate {
            predicates.append(NSPredicate(format: "startTime <= %@", endDate as NSDate))
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        return coreDataManager.fetchAll(SleepRecord.self, sortDescriptors: sortDescriptors, predicate: predicate)
    }
    
    /// 獲取當前進行中的睡眠記錄
    func getOngoingSleepRecord(forBaby baby: Baby) -> SleepRecord? {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "baby == %@", baby),
            NSPredicate(format: "endTime == nil")
        ])
        
        let records = coreDataManager.fetchAll(SleepRecord.self, predicate: predicate)
        return records.first
    }
    
    /// 創建新的睡眠記錄
    func createSleepRecord(forBaby baby: Baby, startTime: Date) -> SleepRecord {
        let sleepRecord = SleepRecord.create(baby: baby, startTime: startTime, in: coreDataManager.viewContext)
        coreDataManager.saveContext()
        return sleepRecord
    }
    
    /// 結束睡眠記錄
    func endSleepRecord(_ sleepRecord: SleepRecord, endTime: Date, quality: Int16? = nil, notes: String? = nil) {
        sleepRecord.end(at: endTime, quality: quality, notes: notes)
        coreDataManager.saveContext()
    }
    
    /// 添加環境因素
    func addEnvironmentFactor(toSleepRecord sleepRecord: SleepRecord, type: String, value: String) -> EnvironmentFactor {
        let factor = EnvironmentFactor.create(sleepRecord: sleepRecord, type: type, value: value, in: coreDataManager.viewContext)
        coreDataManager.saveContext()
        return factor
    }
    
    /// 添加睡眠中斷
    func addSleepInterruption(toSleepRecord sleepRecord: SleepRecord, startTime: Date, endTime: Date, reason: String? = nil) -> SleepInterruption {
        let interruption = SleepInterruption.create(sleepRecord: sleepRecord, startTime: startTime, endTime: endTime, reason: reason, in: coreDataManager.viewContext)
        coreDataManager.saveContext()
        return interruption
    }
    
    /// 刪除睡眠記錄
    func deleteSleepRecord(_ sleepRecord: SleepRecord) {
        coreDataManager.delete(sleepRecord)
    }
    
    /// 獲取睡眠統計數據
    func getSleepStatistics(forBaby baby: Baby, startDate: Date, endDate: Date) -> (totalSleep: Double, averageQuality: Double, interruptionCount: Int) {
        let records = getSleepRecords(forBaby: baby, startDate: startDate, endDate: endDate)
        
        // 只考慮已完成的睡眠記錄
        let completedRecords = records.filter { $0.endTime != nil && $0.duration > 0 }
        
        let totalSleep = completedRecords.reduce(0) { $0 + ($1.duration ?? 0) }
        
        let qualityRecords = completedRecords.filter { $0.quality > 0 }
        let averageQuality = qualityRecords.isEmpty ? 0 : qualityRecords.reduce(0) { $0 + Double($1.quality) } / Double(qualityRecords.count)
        
        let interruptionCount = completedRecords.reduce(0) { $0 + Int($1.interruptionCount) }
        
        return (totalSleep, averageQuality, interruptionCount)
    }
}
```

## 領域層（Domain Layer）

以下是領域層的實現，包含業務邏輯和用例。

### SleepUseCases

```swift
import Foundation
import Combine

/// 睡眠相關用例
class SleepUseCases {
    
    private let sleepRepository: SleepRepository
    private let babyRepository: BabyRepository
    
    init(sleepRepository: SleepRepository = SleepRepository(), babyRepository: BabyRepository = BabyRepository()) {
        self.sleepRepository = sleepRepository
        self.babyRepository = babyRepository
    }
    
    /// 開始睡眠記錄
    func startSleepRecord(forBabyId babyId: UUID, startTime: Date = Date()) -> SleepRecord? {
        guard let baby = babyRepository.getBaby(byId: babyId) else {
            print("找不到指定的寶寶")
            return nil
        }
        
        // 檢查是否已有進行中的睡眠記錄
        if let ongoingRecord = sleepRepository.getOngoingSleepRecord(forBaby: baby) {
            print("已有進行中的睡眠記錄，請先結束該記錄")
            return ongoingRecord
        }
        
        return sleepRepository.createSleepRecord(forBaby: baby, startTime: startTime)
    }
    
    /// 結束睡眠記錄
    func endSleepRecord(recordId: UUID, endTime: Date = Date(), quality: Int? = nil, notes: String? = nil) -> Bool {
        let predicate = NSPredicate(format: "id == %@", recordId as CVarArg)
        let records = CoreDataManager.shared.fetchAll(SleepRecord.self, predicate: predicate)
        
        guard let record = records.first else {
            print("找不到指定的睡眠記錄")
            return false
        }
        
        sleepRepository.endSleepRecord(record, endTime: endTime, quality: quality != nil ? Int16(quality!) : nil, notes: notes)
        return true
    }
    
    /// 添加環境因素
    func addEnvironmentFactor(toSleepRecordId recordId: UUID, type: String, value: String) -> Bool {
        let predicate = NSPredicate(format: "id == %@", recordId as CVarArg)
        let records = CoreDataManager.shared.fetchAll(SleepRecord.self, predicate: predicate)
        
        guard let record = records.first else {
            print("找不到指定的睡眠記錄")
            return false
        }
        
        _ = sleepRepository.addEnvironmentFactor(toSleepRecord: record, type: type, value: value)
        return true
    }
    
    /// 記錄睡眠中斷
    func recordSleepInterruption(forSleepRecordId recordId: UUID, startTime: Date, endTime: Date, reason: String? = nil) -> Bool {
        let predicate = NSPredicate(format: "id == %@", recordId as CVarArg)
        let records = CoreDataManager.shared.fetchAll(SleepRecord.self, predicate: predicate)
        
        guard let record = records.first else {
            print("找不到指定的睡眠記錄")
            return false
        }
        
        _ = sleepRepository.addSleepInterruption(toSleepRecord: record, startTime: startTime, endTime: endTime, reason: reason)
        return true
    }
    
    /// 獲取寶寶的睡眠記錄
    func getSleepRecords(forBabyId babyId: UUID, days: Int = 7) -> [SleepRecord] {
        guard let baby = babyRepository.getBaby(byId: babyId) else {
            print("找不到指定的寶寶")
            return []
        }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        return sleepRepository.getSleepRecords(forBaby: baby, startDate: startDate, endDate: endDate)
    }
    
    /// 獲取寶寶的睡眠統計數據
    func getSleepStatistics(forBabyId babyId: UUID, days: Int = 7) -> (totalSleep: Double, averageQuality: Double, interruptionCount: Int)? {
        guard let baby = babyRepository.getBaby(byId: babyId) else {
            print("找不到指定的寶寶")
            return nil
        }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        return sleepRepository.getSleepStatistics(forBaby: baby, startDate: startDate, endDate: endDate)
    }
    
    /// 檢查是否有進行中的睡眠記錄
    func hasOngoingSleep
(Content truncated due to size limit. Use line ranges to read in chunks)