# 寶寶生活記錄專業版（Baby Tracker）- 級聯刪除規則實現

## 1. 問題描述

在第一階段與第二階段整合性驗證中，發現第二階段UI未實現第一階段定義的級聯刪除規則。當刪除Baby或SleepRecord實體時，相關的子實體（如SleepRecord、SleepInterruption、EnvironmentFactor等）沒有被自動刪除，可能導致孤立數據的產生。這種數據不一致性會導致以下問題：

1. 數據庫中存在無效引用，佔用存儲空間
2. 查詢結果可能包含孤立數據，影響數據分析準確性
3. 應用可能嘗試訪問不存在的父實體，導致崩潰
4. 數據完整性受損，影響用戶體驗

## 2. 修正方案

### 2.1 Core Data模型級聯刪除規則

首先，需要在Core Data模型中設置正確的級聯刪除規則：

```swift
// 在CoreDataManager中設置實體關係的級聯刪除規則
func setupCoreDataModel() {
    // 獲取實體描述
    guard let babyEntity = NSEntityDescription.entity(forEntityName: "BabyEntity", in: persistentContainer.viewContext),
          let sleepRecordEntity = NSEntityDescription.entity(forEntityName: "SleepRecordEntity", in: persistentContainer.viewContext),
          let sleepInterruptionEntity = NSEntityDescription.entity(forEntityName: "SleepInterruptionEntity", in: persistentContainer.viewContext),
          let environmentFactorEntity = NSEntityDescription.entity(forEntityName: "EnvironmentFactorEntity", in: persistentContainer.viewContext) else {
        fatalError("Failed to get entity descriptions")
    }
    
    // 設置Baby -> SleepRecord的級聯刪除規則
    if let relationship = babyEntity.relationshipsByName["sleepRecords"] {
        relationship.deleteRule = .cascadeDeleteRule
    }
    
    // 設置SleepRecord -> SleepInterruption的級聯刪除規則
    if let relationship = sleepRecordEntity.relationshipsByName["interruptions"] {
        relationship.deleteRule = .cascadeDeleteRule
    }
    
    // 設置SleepRecord -> EnvironmentFactor的級聯刪除規則
    if let relationship = sleepRecordEntity.relationshipsByName["environmentFactors"] {
        relationship.deleteRule = .cascadeDeleteRule
    }
}
```

### 2.2 Repository層級聯刪除實現

除了Core Data模型級聯刪除外，還需要在Repository層確保級聯刪除的正確實現：

```swift
// BabyRepository實現中的刪除方法
func deleteBaby(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
    persistentContainer.performBackgroundTask { context in
        do {
            // 查找要刪除的Baby實體
            let fetchRequest: NSFetchRequest<BabyEntity> = BabyEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            
            if let babyEntity = results.first {
                // Core Data會自動處理級聯刪除
                context.delete(babyEntity)
                try context.save()
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(RepositoryError.entityNotFound))
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}

// SleepRepository實現中的刪除方法
func deleteSleepRecord(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
    persistentContainer.performBackgroundTask { context in
        do {
            // 查找要刪除的SleepRecord實體
            let fetchRequest: NSFetchRequest<SleepRecordEntity> = SleepRecordEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            
            if let sleepRecordEntity = results.first {
                // Core Data會自動處理級聯刪除
                context.delete(sleepRecordEntity)
                try context.save()
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(RepositoryError.entityNotFound))
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}
```

### 2.3 UseCase層級聯刪除實現

在UseCase層，需要確保刪除操作正確傳遞到Repository層：

```swift
// DeleteBabyUseCase
class DeleteBabyUseCase {
    private let babyRepository: BabyRepository
    
    init(babyRepository: BabyRepository) {
        self.babyRepository = babyRepository
    }
    
    func execute(babyId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        babyRepository.deleteBaby(id: babyId, completion: completion)
    }
}

// DeleteSleepRecordUseCase
class DeleteSleepRecordUseCase {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func execute(sleepRecordId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        sleepRepository.deleteSleepRecord(id: sleepRecordId, completion: completion)
    }
}
```

### 2.4 ViewModel層級聯刪除使用

在ViewModel層，需要使用上述UseCase進行刪除操作：

```swift
// BabyManagementViewModel
class BabyManagementViewModel: ObservableObject {
    @Published var babies: [BabyViewModel] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let getBabiesUseCase: GetBabiesUseCase
    private let deleteBabyUseCase: DeleteBabyUseCase
    
    init(getBabiesUseCase: GetBabiesUseCase, deleteBabyUseCase: DeleteBabyUseCase) {
        self.getBabiesUseCase = getBabiesUseCase
        self.deleteBabyUseCase = deleteBabyUseCase
        loadBabies()
    }
    
    func loadBabies() {
        isLoading = true
        error = nil
        
        getBabiesUseCase.execute { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let babies):
                    self?.babies = babies.map { BabyViewModel(baby: $0) }
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func deleteBaby(id: UUID) {
        isLoading = true
        error = nil
        
        deleteBabyUseCase.execute(babyId: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    // 刪除成功後重新加載寶寶列表
                    self?.loadBabies()
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
}

// SleepHistoryViewModel
class SleepHistoryViewModel: ObservableObject {
    @Published var sleepRecords: [SleepRecordViewModel] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let getSleepRecordsUseCase: GetSleepRecordsUseCase
    private let deleteSleepRecordUseCase: DeleteSleepRecordUseCase
    
    init(getSleepRecordsUseCase: GetSleepRecordsUseCase, deleteSleepRecordUseCase: DeleteSleepRecordUseCase) {
        self.getSleepRecordsUseCase = getSleepRecordsUseCase
        self.deleteSleepRecordUseCase = deleteSleepRecordUseCase
    }
    
    func loadSleepRecords(babyId: UUID) {
        isLoading = true
        error = nil
        
        getSleepRecordsUseCase.execute(babyId: babyId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let records):
                    self?.sleepRecords = records.map { SleepRecordViewModel(record: $0) }
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func deleteSleepRecord(id: UUID) {
        isLoading = true
        error = nil
        
        deleteSleepRecordUseCase.execute(sleepRecordId: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    // 從本地列表中移除已刪除的記錄
                    self?.sleepRecords.removeAll { $0.id == id }
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
}
```

## 3. 具體修正實施

### 3.1 Core Data模型修正

首先，需要修改Core Data模型文件，設置正確的級聯刪除規則：

```swift
// CoreDataManager.swift

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {
        setupCoreDataModel()
    }
    
    // 懶加載持久化容器
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BabyTracker")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    // 設置Core Data模型關係
    private func setupCoreDataModel() {
        let context = persistentContainer.viewContext
        
        // 獲取實體描述
        guard let babyEntity = NSEntityDescription.entity(forEntityName: "BabyEntity", in: context),
              let sleepRecordEntity = NSEntityDescription.entity(forEntityName: "SleepRecordEntity", in: context),
              let sleepInterruptionEntity = NSEntityDescription.entity(forEntityName: "SleepInterruptionEntity", in: context),
              let environmentFactorEntity = NSEntityDescription.entity(forEntityName: "EnvironmentFactorEntity", in: context),
              let activityEntity = NSEntityDescription.entity(forEntityName: "ActivityEntity", in: context) else {
            fatalError("Failed to get entity descriptions")
        }
        
        // 設置Baby -> SleepRecord的級聯刪除規則
        if let relationship = babyEntity.relationshipsByName["sleepRecords"] {
            relationship.deleteRule = .cascadeDeleteRule
        }
        
        // 設置Baby -> Activity的級聯刪除規則
        if let relationship = babyEntity.relationshipsByName["activities"] {
            relationship.deleteRule = .cascadeDeleteRule
        }
        
        // 設置SleepRecord -> SleepInterruption的級聯刪除規則
        if let relationship = sleepRecordEntity.relationshipsByName["interruptions"] {
            relationship.deleteRule = .cascadeDeleteRule
        }
        
        // 設置SleepRecord -> EnvironmentFactor的級聯刪除規則
        if let relationship = sleepRecordEntity.relationshipsByName["environmentFactors"] {
            relationship.deleteRule = .cascadeDeleteRule
        }
    }
    
    // 保存上下文
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
```

### 3.2 Repository實現修正

接下來，修改Repository實現，確保刪除操作正確執行：

```swift
// BabyRepositoryImpl.swift

class BabyRepositoryImpl: BabyRepository {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    // 其他方法...
    
    func deleteBaby(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<BabyEntity> = BabyEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let babyEntity = results.first {
                // 刪除Baby實體，Core Data會自動處理級聯刪除
                context.delete(babyEntity)
                try context.save()
                completion(.success(()))
            } else {
                completion(.failure(RepositoryError.entityNotFound))
            }
        } catch {
            completion(.failure(error))
        }
    }
}

// SleepRepositoryImpl.swift

class SleepRepositoryImpl: SleepRepository {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    // 其他方法...
    
    func deleteSleepRecord(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<SleepRecordEntity> = SleepRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let sleepRecordEntity = results.first {
                // 刪除SleepRecord實體，Core Data會自動處理級聯刪除
                context.delete(sleepRecordEntity)
                try context.save()
                completion(.success(()))
            } else {
                completion(.failure(RepositoryError.entityNotFound))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
```

### 3.3 UseCase實現

實現刪除操作的UseCase：

```swift
// DeleteBabyUseCase.swift

class DeleteBabyUseCase {
    private let babyRepository: BabyRepository
    
    init(babyRepository: BabyRepository) {
        self.babyRepository = babyRepository
    }
    
    func execute(babyId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        babyRepository.deleteBaby(id: babyId, completion: completion)
    }
}

// DeleteSleepRecordUseCase.swift

class DeleteSleepRecordUseCase {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func execute(sleepRecordId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        sleepRepository.deleteSleepRecord(id: sleepRecordId, completion: completion)
    }
}
```

### 3.4 ViewModel實現

修改ViewModel，使用刪除UseCase：

```swift
// BabyManagementViewModel.swift

class BabyManagementViewModel: ObservableObject {
    @Published var babies: [BabyViewModel] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let getBabiesUseCase: GetBabiesUseCase
    private let deleteBabyUseCase: DeleteBabyUseCase
    
    init(getBabiesUseCase: GetBabiesUseCase, deleteBabyUseCase: DeleteBabyUseCase) {
        self.getBabiesUseCase = getBabiesUseCase
        self.deleteBabyUseCase = deleteBabyUseCase
        loadBabies()
    }
    
    func loadBabies() {
        isLoading = true
        error = nil
        
        getBabiesUseCase.execute { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let babies):
                    self?.babies = babies.map { BabyViewModel(baby: $0) }
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func deleteBaby(id: UUID) {
        isLoading = true
        error = nil
        
        deleteBabyUseCase.execute(babyId: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    // 刪除成功後重新加載寶寶列表
                    self?.loadBabies()
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
}

// SleepHistoryViewModel.swift

class SleepHistoryViewModel: ObservableObject {
    @Published var sleepRecords: [SleepRecordViewModel] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let getSleepRecordsUseCase: GetSleepRecordsUseCase
    private let deleteSleepRecordUseCase: DeleteSleepRecordUseCase
    
    init(getSleepRecordsUseCase: GetSleepRecordsUseCase, deleteSleepRecordUseCase: DeleteSleepRecordUseCase) {
        self.getSleepRecordsUseCase = getSleepRecordsUseCase
        self.deleteSleepRecordUseCase = deleteSleep
(Content truncated due to size limit. Use line ranges to read in chunks)