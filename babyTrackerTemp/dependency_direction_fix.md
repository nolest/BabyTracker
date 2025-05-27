# 寶寶生活記錄專業版（Baby Tracker）- 依賴方向修正

## 1. 問題描述

在第二階段UI與體驗開發中，發現某些視圖模型（ViewModel）直接依賴Repository層，跳過了UseCase層，違反了第一階段建立的架構原則。這種依賴方向的不一致會導致以下問題：

1. 破壞了Clean Architecture的層次結構
2. 降低了代碼的可測試性
3. 增加了模塊間的耦合度
4. 使業務邏輯分散在不同層次，難以維護

## 2. 修正方案

### 2.1 識別問題代碼

首先識別所有直接依賴Repository的視圖模型：

```swift
// 問題代碼示例：直接依賴Repository的視圖模型
class SleepDashboardViewModel: ObservableObject {
    @Published var recentSleepRecords: [SleepRecordViewModel] = []
    
    // 直接注入Repository，違反架構原則
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
        loadRecentSleepRecords()
    }
    
    private func loadRecentSleepRecords() {
        // 直接調用Repository方法
        sleepRepository.getRecentSleepRecords(limit: 5) { [weak self] result in
            switch result {
            case .success(let records):
                self?.recentSleepRecords = records.map { SleepRecordViewModel(record: $0) }
            case .failure(let error):
                print("Failed to load sleep records: \(error)")
            }
        }
    }
}
```

### 2.2 創建或使用適當的UseCase

為每個視圖模型創建或使用適當的UseCase，確保業務邏輯集中在UseCase層：

```swift
// 創建適當的UseCase
class GetRecentSleepRecordsUseCase {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func execute(limit: Int, completion: @escaping (Result<[SleepRecord], Error>) -> Void) {
        sleepRepository.getRecentSleepRecords(limit: limit, completion: completion)
    }
}
```

### 2.3 修改視圖模型依賴

修改視圖模型，使其依賴UseCase而非Repository：

```swift
// 修正後的代碼：依賴UseCase的視圖模型
class SleepDashboardViewModel: ObservableObject {
    @Published var recentSleepRecords: [SleepRecordViewModel] = []
    
    // 依賴UseCase，符合架構原則
    private let getRecentSleepRecordsUseCase: GetRecentSleepRecordsUseCase
    
    init(getRecentSleepRecordsUseCase: GetRecentSleepRecordsUseCase) {
        self.getRecentSleepRecordsUseCase = getRecentSleepRecordsUseCase
        loadRecentSleepRecords()
    }
    
    private func loadRecentSleepRecords() {
        // 調用UseCase方法
        getRecentSleepRecordsUseCase.execute(limit: 5) { [weak self] result in
            switch result {
            case .success(let records):
                self?.recentSleepRecords = records.map { SleepRecordViewModel(record: $0) }
            case .failure(let error):
                print("Failed to load sleep records: \(error)")
            }
        }
    }
}
```

### 2.4 更新依賴注入

更新依賴注入代碼，確保正確創建和注入UseCase：

```swift
// 依賴注入示例
func configureSleepDashboardViewModel() -> SleepDashboardViewModel {
    let coreDataManager = CoreDataManager.shared
    let sleepRepository = SleepRepositoryImpl(coreDataManager: coreDataManager)
    let getRecentSleepRecordsUseCase = GetRecentSleepRecordsUseCase(sleepRepository: sleepRepository)
    return SleepDashboardViewModel(getRecentSleepRecordsUseCase: getRecentSleepRecordsUseCase)
}
```

## 3. 具體修正實施

以下是需要修正的具體視圖模型及其對應的UseCase：

### 3.1 SleepDashboardViewModel

**問題**：直接依賴SleepRepository獲取最近睡眠記錄。

**修正**：
1. 創建GetRecentSleepRecordsUseCase
2. 修改SleepDashboardViewModel依賴GetRecentSleepRecordsUseCase
3. 更新依賴注入

```swift
// UseCase實現
class GetRecentSleepRecordsUseCase {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func execute(limit: Int, completion: @escaping (Result<[SleepRecord], Error>) -> Void) {
        sleepRepository.getRecentSleepRecords(limit: limit, completion: completion)
    }
}

// 修正後的ViewModel
class SleepDashboardViewModel: ObservableObject {
    @Published var recentSleepRecords: [SleepRecordViewModel] = []
    
    private let getRecentSleepRecordsUseCase: GetRecentSleepRecordsUseCase
    
    init(getRecentSleepRecordsUseCase: GetRecentSleepRecordsUseCase) {
        self.getRecentSleepRecordsUseCase = getRecentSleepRecordsUseCase
        loadRecentSleepRecords()
    }
    
    private func loadRecentSleepRecords() {
        getRecentSleepRecordsUseCase.execute(limit: 5) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    self?.recentSleepRecords = records.map { SleepRecordViewModel(record: $0) }
                case .failure(let error):
                    print("Failed to load sleep records: \(error)")
                    // 錯誤處理將在統一錯誤處理修正中完善
                }
            }
        }
    }
}
```

### 3.2 SleepRecordViewModel

**問題**：直接依賴SleepRepository和EnvironmentFactorRepository保存睡眠記錄和環境因素。

**修正**：
1. 創建SaveSleepRecordUseCase和SaveEnvironmentFactorUseCase
2. 修改SleepRecordViewModel依賴這些UseCase
3. 更新依賴注入

```swift
// UseCase實現
class SaveSleepRecordUseCase {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func execute(sleepRecord: SleepRecord, completion: @escaping (Result<SleepRecord, Error>) -> Void) {
        sleepRepository.saveSleepRecord(sleepRecord, completion: completion)
    }
}

class SaveEnvironmentFactorUseCase {
    private let environmentFactorRepository: EnvironmentFactorRepository
    
    init(environmentFactorRepository: EnvironmentFactorRepository) {
        self.environmentFactorRepository = environmentFactorRepository
    }
    
    func execute(factor: EnvironmentFactor, completion: @escaping (Result<EnvironmentFactor, Error>) -> Void) {
        environmentFactorRepository.saveEnvironmentFactor(factor, completion: completion)
    }
}

// 修正後的ViewModel
class SleepRecordViewModel: ObservableObject {
    @Published var startTime: Date
    @Published var endTime: Date?
    @Published var environmentFactors: [EnvironmentFactorViewModel] = []
    
    private let saveSleepRecordUseCase: SaveSleepRecordUseCase
    private let saveEnvironmentFactorUseCase: SaveEnvironmentFactorUseCase
    
    init(saveSleepRecordUseCase: SaveSleepRecordUseCase, 
         saveEnvironmentFactorUseCase: SaveEnvironmentFactorUseCase,
         startTime: Date = Date(), 
         endTime: Date? = nil) {
        self.saveSleepRecordUseCase = saveSleepRecordUseCase
        self.saveEnvironmentFactorUseCase = saveEnvironmentFactorUseCase
        self.startTime = startTime
        self.endTime = endTime
    }
    
    func saveSleepRecord(babyId: UUID, completion: @escaping (Result<SleepRecord, Error>) -> Void) {
        let sleepRecord = SleepRecord(
            id: UUID(),
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            quality: calculateQuality(),
            notes: ""
        )
        
        saveSleepRecordUseCase.execute(sleepRecord: sleepRecord) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedRecord):
                    // 保存環境因素
                    self?.saveEnvironmentFactors(for: savedRecord.id)
                    completion(.success(savedRecord))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func saveEnvironmentFactors(for sleepRecordId: UUID) {
        for factorVM in environmentFactors {
            let factor = EnvironmentFactor(
                id: UUID(),
                sleepRecordId: sleepRecordId,
                type: factorVM.type,
                value: factorVM.value,
                notes: factorVM.notes
            )
            
            saveEnvironmentFactorUseCase.execute(factor: factor) { result in
                // 處理結果
            }
        }
    }
    
    private func calculateQuality() -> Int {
        // 睡眠質量計算邏輯
        return 5 // 示例值
    }
}
```

### 3.3 BabySelectorViewModel

**問題**：直接依賴BabyRepository獲取寶寶列表。

**修正**：
1. 創建GetBabiesUseCase
2. 修改BabySelectorViewModel依賴GetBabiesUseCase
3. 更新依賴注入

```swift
// UseCase實現
class GetBabiesUseCase {
    private let babyRepository: BabyRepository
    
    init(babyRepository: BabyRepository) {
        self.babyRepository = babyRepository
    }
    
    func execute(completion: @escaping (Result<[Baby], Error>) -> Void) {
        babyRepository.getAllBabies(completion: completion)
    }
}

// 修正後的ViewModel
class BabySelectorViewModel: ObservableObject {
    @Published var babies: [BabyViewModel] = []
    @Published var selectedBabyId: UUID?
    
    private let getBabiesUseCase: GetBabiesUseCase
    
    init(getBabiesUseCase: GetBabiesUseCase) {
        self.getBabiesUseCase = getBabiesUseCase
        loadBabies()
    }
    
    private func loadBabies() {
        getBabiesUseCase.execute { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let babies):
                    self?.babies = babies.map { BabyViewModel(baby: $0) }
                    if let firstBaby = babies.first {
                        self?.selectedBabyId = firstBaby.id
                    }
                case .failure(let error):
                    print("Failed to load babies: \(error)")
                    // 錯誤處理將在統一錯誤處理修正中完善
                }
            }
        }
    }
    
    func selectBaby(id: UUID) {
        selectedBabyId = id
    }
}
```

### 3.4 SleepAnalyticsViewModel

**問題**：直接依賴SleepRepository獲取睡眠分析數據。

**修正**：
1. 創建GetSleepAnalyticsUseCase
2. 修改SleepAnalyticsViewModel依賴GetSleepAnalyticsUseCase
3. 更新依賴注入

```swift
// UseCase實現
class GetSleepAnalyticsUseCase {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func execute(babyId: UUID, timeRange: TimeRange, completion: @escaping (Result<SleepAnalytics, Error>) -> Void) {
        sleepRepository.getSleepAnalytics(babyId: babyId, timeRange: timeRange, completion: completion)
    }
}

// 修正後的ViewModel
class SleepAnalyticsViewModel: ObservableObject {
    @Published var sleepDurationData: [Double] = []
    @Published var sleepQualityData: [Int] = []
    @Published var dateLabels: [String] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let getSleepAnalyticsUseCase: GetSleepAnalyticsUseCase
    private let dateFormatter: DateFormatter
    
    init(getSleepAnalyticsUseCase: GetSleepAnalyticsUseCase) {
        self.getSleepAnalyticsUseCase = getSleepAnalyticsUseCase
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MM/dd"
    }
    
    func loadAnalytics(babyId: UUID, timeRange: TimeRange) {
        isLoading = true
        error = nil
        
        getSleepAnalyticsUseCase.execute(babyId: babyId, timeRange: timeRange) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let analytics):
                    self?.processSleepAnalytics(analytics)
                case .failure(let error):
                    self?.error = error
                    // 錯誤處理將在統一錯誤處理修正中完善
                }
            }
        }
    }
    
    private func processSleepAnalytics(_ analytics: SleepAnalytics) {
        sleepDurationData = analytics.dailySleepDurations
        sleepQualityData = analytics.dailySleepQualities
        dateLabels = analytics.dates.map { dateFormatter.string(from: $0) }
    }
}
```

### 3.5 EnvironmentFactorViewModel

**問題**：直接依賴EnvironmentFactorRepository保存環境因素。

**修正**：
1. 使用已創建的SaveEnvironmentFactorUseCase
2. 修改EnvironmentFactorViewModel依賴SaveEnvironmentFactorUseCase
3. 更新依賴注入

```swift
// 修正後的ViewModel
class EnvironmentFactorViewModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var type: EnvironmentFactorType
    @Published var value: Int
    @Published var notes: String
    
    private let saveEnvironmentFactorUseCase: SaveEnvironmentFactorUseCase?
    
    init(type: EnvironmentFactorType = .noise, 
         value: Int = 3, 
         notes: String = "",
         saveEnvironmentFactorUseCase: SaveEnvironmentFactorUseCase? = nil) {
        self.type = type
        self.value = value
        self.notes = notes
        self.saveEnvironmentFactorUseCase = saveEnvironmentFactorUseCase
    }
    
    init(factor: EnvironmentFactor, saveEnvironmentFactorUseCase: SaveEnvironmentFactorUseCase? = nil) {
        self.type = factor.type
        self.value = factor.value
        self.notes = factor.notes
        self.saveEnvironmentFactorUseCase = saveEnvironmentFactorUseCase
    }
    
    func save(for sleepRecordId: UUID, completion: @escaping (Result<EnvironmentFactor, Error>) -> Void) {
        guard let saveUseCase = saveEnvironmentFactorUseCase else {
            completion(.failure(NSError(domain: "EnvironmentFactorViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "SaveEnvironmentFactorUseCase not provided"])))
            return
        }
        
        let factor = EnvironmentFactor(
            id: UUID(),
            sleepRecordId: sleepRecordId,
            type: type,
            value: value,
            notes: notes
        )
        
        saveUseCase.execute(factor: factor) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
```

## 4. 依賴注入更新

更新依賴注入代碼，確保正確創建和注入所有UseCase：

```swift
// 依賴注入容器
class DependencyContainer {
    // 單例模式
    static let shared = DependencyContainer()
    
    // 核心依賴
    private let coreDataManager = CoreDataManager.shared
    
    // Repositories
    lazy var babyRepository: BabyRepository = {
        return BabyRepositoryImpl(coreDataManager: coreDataManager)
    }()
    
    lazy var sleepRepository: SleepRepository = {
        return SleepRepositoryImpl(coreDataManager: coreDataManager)
    }()
    
    lazy var environmentFactorRepository: EnvironmentFactorRepository = {
        return EnvironmentFactorRepositoryImpl(coreDataManager: coreDataManager)
    }()
    
    // UseCases
    lazy var getBabiesUseCase: GetBabiesUseCase = {
        return GetBabiesUseCase(babyRepository: babyRepository)
    }()
    
    lazy var getRecentSleepRecordsUseCase: GetRecentSleepRecordsUseCase = {
        return GetRecentSleepRecordsUseCase(sleepRepository: sleepRepository)
    }()
    
    lazy var saveSleepRecordUseCase: SaveSleepRecordUseCase = {
        return SaveSleepRecordUseCase(sleepRepository: sleepRepository)
    }()
    
    lazy var saveEnvironmentFactorUseCase: SaveEnvironmentFactorUseCase = {
        return SaveEnvironmentFactorUseCase(environmentFactorRepository: environmentFactorRepository)
    }()
    
    lazy var getSleepAnalyticsUseCase: GetSleepAnalyticsUseCase = {
        return GetSleepAnalyticsUseCase(sleepRepository: sleepRepository)
    }()
    
    // ViewModels
    func makeBabySelectorViewModel() -> BabySelectorViewModel {
        return BabySelectorViewModel(getBabiesUseCase: getBabiesUseCase)
    }
    
    func makeSleepDashboardViewModel() -> SleepDashboardViewModel {
        return SleepDashboardViewModel(getRecentSleepRecordsUseCase: getRecentSleepRecordsUseCase)
    }
    
    func makeSleepRecordViewModel() -> SleepRecordViewModel {
        return SleepRecordViewModel(
            saveSleepRecordUseCase: saveSleepRecordUseCase,
            saveEnvironmentFactorUseCase: saveEnvironmentFactorUseCase
        )
    }
    
    func makeSleepAnalyticsViewModel() -> SleepAnalyticsViewModel {
        return SleepAnalyticsViewModel(getSleepAnalyticsUseCase: getSleepAnalyticsUseCase)
    }
    
    func makeEnvironmentFactorViewModel(type: EnvironmentFactorType = .noise, value: Int = 3, notes: String = "") -> EnvironmentFactorViewModel {
        return EnvironmentFactorViewModel(
            type: type,
            value: value,
            notes: notes,
            saveEnvironmentFac
(Content truncated due to size limit. Use line ranges to read in chunks)