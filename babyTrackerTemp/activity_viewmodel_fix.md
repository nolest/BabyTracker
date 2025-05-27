# 寶寶生活記錄專業版（Baby Tracker）- 完善ActivityViewModel

## 1. 問題描述

在第一階段與第二階段整合性驗證中，發現第二階段的ActivityViewModel未完全映射第一階段定義的Activity實體的所有屬性，主要關注了睡眠相關活動，而忽略了其他類型的活動。這種不完整的映射會導致以下問題：

1. 無法完整展示和管理所有類型的活動
2. 數據模型與視圖模型之間存在不一致性
3. 第三階段AI分析功能可能無法獲取完整的活動數據
4. 用戶體驗受限，無法記錄和查看所有類型的活動

## 2. 修正方案

### 2.1 回顧Activity實體定義

首先，回顧第一階段定義的Activity實體：

```swift
// Activity.swift

enum ActivityType: String, Codable, CaseIterable {
    case sleep = "sleep"
    case feeding = "feeding"
    case diaper = "diaper"
    case bath = "bath"
    case play = "play"
    case medicine = "medicine"
    case growth = "growth"
    case milestone = "milestone"
    case other = "other"
}

struct Activity: Identifiable {
    let id: UUID
    let babyId: UUID
    let type: ActivityType
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval?
    let value: Double?
    let unit: String?
    let notes: String
    let createdAt: Date
    let updatedAt: Date
}
```

### 2.2 完善ActivityViewModel

接下來，完善ActivityViewModel，確保完全映射Activity實體的所有屬性：

```swift
// ActivityViewModel.swift

class ActivityViewModel: ObservableObject, Identifiable {
    let id: UUID
    let babyId: UUID
    @Published var type: ActivityType
    @Published var startTime: Date
    @Published var endTime: Date?
    @Published var duration: TimeInterval?
    @Published var value: Double?
    @Published var unit: String?
    @Published var notes: String
    let createdAt: Date
    let updatedAt: Date
    
    @Published var isLoading: Bool = false
    
    private let saveActivityUseCase: SaveActivityUseCase
    private let errorHandler: ErrorHandlingService
    
    // 初始化方法 - 從實體創建
    init(activity: Activity, saveActivityUseCase: SaveActivityUseCase, errorHandler: ErrorHandlingService) {
        self.id = activity.id
        self.babyId = activity.babyId
        self.type = activity.type
        self.startTime = activity.startTime
        self.endTime = activity.endTime
        self.duration = activity.duration
        self.value = activity.value
        self.unit = activity.unit
        self.notes = activity.notes
        self.createdAt = activity.createdAt
        self.updatedAt = activity.updatedAt
        self.saveActivityUseCase = saveActivityUseCase
        self.errorHandler = errorHandler
    }
    
    // 初始化方法 - 創建新活動
    init(id: UUID = UUID(),
         babyId: UUID,
         type: ActivityType = .sleep,
         startTime: Date = Date(),
         endTime: Date? = nil,
         duration: TimeInterval? = nil,
         value: Double? = nil,
         unit: String? = nil,
         notes: String = "",
         saveActivityUseCase: SaveActivityUseCase,
         errorHandler: ErrorHandlingService) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.value = value
        self.unit = unit
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.saveActivityUseCase = saveActivityUseCase
        self.errorHandler = errorHandler
    }
    
    // 保存活動
    func saveActivity(completion: @escaping () -> Void) {
        isLoading = true
        
        // 計算持續時間（如果有結束時間）
        let calculatedDuration: TimeInterval?
        if let endTime = endTime {
            calculatedDuration = endTime.timeIntervalSince(startTime)
        } else {
            calculatedDuration = duration
        }
        
        let activity = Activity(
            id: id,
            babyId: babyId,
            type: type,
            startTime: startTime,
            endTime: endTime,
            duration: calculatedDuration,
            value: value,
            unit: unit,
            notes: notes,
            createdAt: createdAt,
            updatedAt: Date()
        )
        
        saveActivityUseCase.execute(activity: activity) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                self.errorHandler.handleResult(result) { _ in
                    completion()
                }
            }
        }
    }
    
    // 開始計時活動
    func startActivity() {
        startTime = Date()
        endTime = nil
        duration = nil
    }
    
    // 結束計時活動
    func endActivity() {
        endTime = Date()
        if let end = endTime {
            duration = end.timeIntervalSince(startTime)
        }
    }
    
    // 獲取格式化的持續時間
    var formattedDuration: String {
        guard let duration = self.duration ?? (endTime?.timeIntervalSince(startTime)) else {
            return "未完成"
        }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d小時%02d分鐘", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分鐘%02d秒", minutes, seconds)
        } else {
            return String(format: "%d秒", seconds)
        }
    }
    
    // 獲取活動類型的本地化名稱
    var typeLocalizedName: String {
        switch type {
        case .sleep:
            return "睡眠"
        case .feeding:
            return "餵食"
        case .diaper:
            return "換尿布"
        case .bath:
            return "洗澡"
        case .play:
            return "玩耍"
        case .medicine:
            return "用藥"
        case .growth:
            return "成長記錄"
        case .milestone:
            return "里程碑"
        case .other:
            return "其他"
        }
    }
    
    // 獲取活動類型的圖標名稱
    var typeIconName: String {
        switch type {
        case .sleep:
            return "moon.zzz"
        case .feeding:
            return "bottle"
        case .diaper:
            return "heart.text.square"
        case .bath:
            return "drop"
        case .play:
            return "gamecontroller"
        case .medicine:
            return "pills"
        case .growth:
            return "ruler"
        case .milestone:
            return "flag"
        case .other:
            return "square.and.pencil"
        }
    }
    
    // 獲取活動類型的顏色
    var typeColor: Color {
        switch type {
        case .sleep:
            return Color.blue
        case .feeding:
            return Color.green
        case .diaper:
            return Color.yellow
        case .bath:
            return Color.cyan
        case .play:
            return Color.orange
        case .medicine:
            return Color.red
        case .growth:
            return Color.purple
        case .milestone:
            return Color.pink
        case .other:
            return Color.gray
        }
    }
    
    // 將ViewModel轉換為領域實體
    func toDomain() -> Activity {
        return Activity(
            id: id,
            babyId: babyId,
            type: type,
            startTime: startTime,
            endTime: endTime,
            duration: duration ?? (endTime?.timeIntervalSince(startTime)),
            value: value,
            unit: unit,
            notes: notes,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
```

### 2.3 實現ActivityListViewModel

為了管理活動列表，實現ActivityListViewModel：

```swift
// ActivityListViewModel.swift

class ActivityListViewModel: ObservableObject {
    @Published var activities: [ActivityViewModel] = []
    @Published var isLoading: Bool = false
    @Published var selectedType: ActivityType?
    
    private let getActivitiesUseCase: GetActivitiesUseCase
    private let saveActivityUseCase: SaveActivityUseCase
    private let deleteActivityUseCase: DeleteActivityUseCase
    private let errorHandler: ErrorHandlingService
    
    init(getActivitiesUseCase: GetActivitiesUseCase,
         saveActivityUseCase: SaveActivityUseCase,
         deleteActivityUseCase: DeleteActivityUseCase,
         errorHandler: ErrorHandlingService) {
        self.getActivitiesUseCase = getActivitiesUseCase
        self.saveActivityUseCase = saveActivityUseCase
        self.deleteActivityUseCase = deleteActivityUseCase
        self.errorHandler = errorHandler
    }
    
    // 加載活動列表
    func loadActivities(babyId: UUID, type: ActivityType? = nil) {
        isLoading = true
        selectedType = type
        
        getActivitiesUseCase.execute(babyId: babyId, type: type) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                self.errorHandler.handleResult(result) { activities in
                    self.activities = activities.map { activity in
                        ActivityViewModel(
                            activity: activity,
                            saveActivityUseCase: self.saveActivityUseCase,
                            errorHandler: self.errorHandler
                        )
                    }
                }
            }
        }
    }
    
    // 刪除活動
    func deleteActivity(id: UUID) {
        isLoading = true
        
        deleteActivityUseCase.execute(activityId: id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                self.errorHandler.handleResult(result) { _ in
                    // 從列表中移除已刪除的活動
                    self.activities.removeAll { $0.id == id }
                }
            }
        }
    }
    
    // 創建新活動ViewModel
    func createActivityViewModel(babyId: UUID, type: ActivityType) -> ActivityViewModel {
        return ActivityViewModel(
            babyId: babyId,
            type: type,
            saveActivityUseCase: saveActivityUseCase,
            errorHandler: errorHandler
        )
    }
    
    // 按日期分組的活動
    var activitiesByDate: [Date: [ActivityViewModel]] {
        let calendar = Calendar.current
        
        return Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.startTime)
        }
    }
    
    // 排序後的日期
    var sortedDates: [Date] {
        return activitiesByDate.keys.sorted(by: >)
    }
}
```

### 2.4 實現ActivityRepository接口和實現

確保ActivityRepository接口完整，並實現所有方法：

```swift
// ActivityRepository.swift

protocol ActivityRepository {
    func getActivities(babyId: UUID, type: ActivityType?, completion: @escaping (Result<[Activity], Error>) -> Void)
    func getActivity(id: UUID, completion: @escaping (Result<Activity, Error>) -> Void)
    func saveActivity(activity: Activity, completion: @escaping (Result<Activity, Error>) -> Void)
    func deleteActivity(id: UUID, completion: @escaping (Result<Void, Error>) -> Void)
}

// ActivityRepositoryImpl.swift

class ActivityRepositoryImpl: ActivityRepository {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    func getActivities(babyId: UUID, type: ActivityType?, completion: @escaping (Result<[Activity], Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<ActivityEntity> = ActivityEntity.fetchRequest()
        
        // 構建查詢條件
        var predicates: [NSPredicate] = [NSPredicate(format: "babyId == %@", babyId as CVarArg)]
        
        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            let activityEntities = try context.fetch(fetchRequest)
            let activities = activityEntities.map { $0.toDomain() }
            completion(.success(activities))
        } catch {
            let appError = AppError.dataError("無法獲取活動列表：\(error.localizedDescription)")
            completion(.failure(appError))
        }
    }
    
    func getActivity(id: UUID, completion: @escaping (Result<Activity, Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<ActivityEntity> = ActivityEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let activityEntity = results.first {
                let activity = activityEntity.toDomain()
                completion(.success(activity))
            } else {
                let appError = AppError.entityNotFound("找不到ID為\(id)的活動")
                completion(.failure(appError))
            }
        } catch {
            let appError = AppError.dataError("獲取活動時出錯：\(error.localizedDescription)")
            completion(.failure(appError))
        }
    }
    
    func saveActivity(activity: Activity, completion: @escaping (Result<Activity, Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        // 檢查是否存在相同ID的實體
        let fetchRequest: NSFetchRequest<ActivityEntity> = ActivityEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", activity.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            let activityEntity: ActivityEntity
            
            if let existingEntity = results.first {
                // 更新現有實體
                activityEntity = existingEntity
            } else {
                // 創建新實體
                activityEntity = ActivityEntity(context: context)
                activityEntity.id = activity.id
                activityEntity.createdAt = activity.createdAt
            }
            
            // 設置實體屬性
            activityEntity.babyId = activity.babyId
            activityEntity.type = activity.type.rawValue
            activityEntity.startTime = activity.startTime
            activityEntity.endTime = activity.endTime
            activityEntity.duration = activity.duration ?? 0
            activityEntity.value = activity.value ?? 0
            activityEntity.unit = activity.unit
            activityEntity.notes = activity.notes
            activityEntity.updatedAt = Date()
            
            try context.save()
            
            let savedActivity = activityEntity.toDomain()
            completion(.success(savedActivity))
        } catch {
            let appError = AppError.dataError("保存活動時出錯：\(error.localizedDescription)")
            completion(.failure(appError))
        }
    }
    
    func deleteActivity(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<ActivityEntity> = ActivityEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let activityEntity = results.first {
                context.delete(activityEntity)
                try context.save()
                completion(.success(()))
            } else {
                let appError = AppError.entityNotFound("找不到ID為\(id)的活動")
                completion(.failure(appError))
            }
        } catch {
            let appError = AppError.dataError("刪除活動時出錯：\(error.localizedDescription)")
            completion(.failure(appError))
        }
    }
}

// ActivityEntity+Extension.swift

extension ActivityEntity {
    func toDomain() -> Activity {
        return Activity(
            id: id ?? UUID(),
            babyId: babyId ?? UUID(),
            type: ActivityType(rawValue: type ?? "") ?? .other,
            startTime: st
(Content truncated due to size limit. Use line ranges to read in chunks)