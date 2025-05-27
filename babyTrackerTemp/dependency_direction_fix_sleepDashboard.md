# 寶寶生活記錄專業版（Baby Tracker）- SleepDashboardViewModel 依賴方向修正

## 1. 問題描述

在整合驗證過程中，發現 SleepDashboardViewModel 仍然直接依賴 SleepRepository，而不是通過 UseCase 層訪問數據。這違反了我們在第一階段建立的架構原則，可能導致以下問題：

1. 架構不一致，增加維護難度
2. 依賴方向混亂，降低代碼可讀性
3. 單元測試困難，無法有效模擬依賴
4. 功能擴展受限，難以添加新的業務邏輯
5. 與其他模塊集成困難，特別是第三階段的 AI 分析功能

## 2. 修正方案

### 2.1 創建 UseCase

首先，創建 GetSleepDashboardDataUseCase 來封裝獲取儀表板數據的業務邏輯：

```swift
// GetSleepDashboardDataUseCase.swift

class GetSleepDashboardDataUseCase {
    private let sleepRepository: SleepRepository
    private let babyRepository: BabyRepository
    
    init(sleepRepository: SleepRepository, babyRepository: BabyRepository) {
        self.sleepRepository = sleepRepository
        self.babyRepository = babyRepository
    }
    
    func execute(babyId: UUID, timeRange: TimeRange, completion: @escaping (Result<SleepDashboardData, Error>) -> Void) {
        // 獲取寶寶信息
        babyRepository.getBaby(id: babyId) { [weak self] babyResult in
            guard let self = self else { return }
            
            switch babyResult {
            case .success(let baby):
                // 獲取睡眠記錄
                self.sleepRepository.getSleepRecords(babyId: babyId, timeRange: timeRange) { sleepRecordsResult in
                    switch sleepRecordsResult {
                    case .success(let sleepRecords):
                        // 處理數據
                        let dashboardData = self.processDashboardData(baby: baby, sleepRecords: sleepRecords, timeRange: timeRange)
                        completion(.success(dashboardData))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func processDashboardData(baby: Baby, sleepRecords: [SleepRecord], timeRange: TimeRange) -> SleepDashboardData {
        // 計算睡眠統計數據
        let totalSleepDuration = calculateTotalSleepDuration(sleepRecords)
        let averageSleepDuration = calculateAverageSleepDuration(sleepRecords)
        let sleepQualityDistribution = calculateSleepQualityDistribution(sleepRecords)
        let sleepTimeDistribution = calculateSleepTimeDistribution(sleepRecords)
        let environmentFactorsImpact = calculateEnvironmentFactorsImpact(sleepRecords)
        
        return SleepDashboardData(
            baby: baby,
            timeRange: timeRange,
            totalSleepDuration: totalSleepDuration,
            averageSleepDuration: averageSleepDuration,
            sleepQualityDistribution: sleepQualityDistribution,
            sleepTimeDistribution: sleepTimeDistribution,
            environmentFactorsImpact: environmentFactorsImpact,
            sleepRecords: sleepRecords
        )
    }
    
    private func calculateTotalSleepDuration(_ sleepRecords: [SleepRecord]) -> TimeInterval {
        return sleepRecords.reduce(0) { total, record in
            guard let endTime = record.endTime else { return total }
            return total + endTime.timeIntervalSince(record.startTime)
        }
    }
    
    private func calculateAverageSleepDuration(_ sleepRecords: [SleepRecord]) -> TimeInterval {
        let completedRecords = sleepRecords.filter { $0.endTime != nil }
        guard !completedRecords.isEmpty else { return 0 }
        
        let totalDuration = calculateTotalSleepDuration(completedRecords)
        return totalDuration / Double(completedRecords.count)
    }
    
    private func calculateSleepQualityDistribution(_ sleepRecords: [SleepRecord]) -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        
        for record in sleepRecords {
            let quality = record.quality
            distribution[quality] = (distribution[quality] ?? 0) + 1
        }
        
        return distribution
    }
    
    private func calculateSleepTimeDistribution(_ sleepRecords: [SleepRecord]) -> [Int: TimeInterval] {
        var distribution: [Int: TimeInterval] = [:]
        
        for record in sleepRecords {
            guard let endTime = record.endTime else { continue }
            
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: record.startTime)
            let duration = endTime.timeIntervalSince(record.startTime)
            
            distribution[hour] = (distribution[hour] ?? 0) + duration
        }
        
        return distribution
    }
    
    private func calculateEnvironmentFactorsImpact(_ sleepRecords: [SleepRecord]) -> [EnvironmentFactorType: [Int: Double]] {
        var impact: [EnvironmentFactorType: [Int: Double]] = [:]
        
        for record in sleepRecords {
            guard let factors = record.environmentFactors else { continue }
            
            for factor in factors {
                if impact[factor.type] == nil {
                    impact[factor.type] = [:]
                }
                
                let quality = record.quality
                let count = impact[factor.type]?[factor.value] ?? 0
                impact[factor.type]?[factor.value] = count + Double(quality)
            }
        }
        
        // 計算平均質量
        for (type, values) in impact {
            for (value, qualitySum) in values {
                let count = sleepRecords.filter { record in
                    guard let factors = record.environmentFactors else { return false }
                    return factors.contains { $0.type == type && $0.value == value }
                }.count
                
                if count > 0 {
                    impact[type]?[value] = qualitySum / Double(count)
                }
            }
        }
        
        return impact
    }
}

// SleepDashboardData.swift

struct SleepDashboardData {
    let baby: Baby
    let timeRange: TimeRange
    let totalSleepDuration: TimeInterval
    let averageSleepDuration: TimeInterval
    let sleepQualityDistribution: [Int: Int]
    let sleepTimeDistribution: [Int: TimeInterval]
    let environmentFactorsImpact: [EnvironmentFactorType: [Int: Double]]
    let sleepRecords: [SleepRecord]
}

// TimeRange.swift

enum TimeRange {
    case day
    case week
    case month
    case custom(from: Date, to: Date)
    
    var title: String {
        switch self {
        case .day:
            return "今日"
        case .week:
            return "本週"
        case .month:
            return "本月"
        case .custom(let from, let to):
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd"
            return "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
        }
    }
    
    var dateRange: (from: Date, to: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components)!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return (startOfMonth, endOfMonth)
        case .custom(let from, let to):
            return (from, to)
        }
    }
}
```

### 2.2 修改 SleepDashboardViewModel

接下來，修改 SleepDashboardViewModel 使用新的 UseCase：

```swift
// SleepDashboardViewModel.swift

class SleepDashboardViewModel: ObservableObject {
    // 輸出數據
    @Published var isLoading: Bool = false
    @Published var selectedTimeRange: TimeRange = .day
    @Published var totalSleepDuration: TimeInterval = 0
    @Published var averageSleepDuration: TimeInterval = 0
    @Published var sleepQualityDistribution: [Int: Int] = [:]
    @Published var sleepTimeDistribution: [Int: TimeInterval] = [:]
    @Published var environmentFactorsImpact: [EnvironmentFactorType: [Int: Double]] = [:]
    @Published var sleepRecords: [SleepRecord] = []
    
    // 依賴
    private let getSleepDashboardDataUseCase: GetSleepDashboardDataUseCase
    private let errorHandler: ErrorHandlingService
    private let babyId: UUID
    
    // 初始化
    init(babyId: UUID, 
         getSleepDashboardDataUseCase: GetSleepDashboardDataUseCase,
         errorHandler: ErrorHandlingService) {
        self.babyId = babyId
        self.getSleepDashboardDataUseCase = getSleepDashboardDataUseCase
        self.errorHandler = errorHandler
        
        loadData()
    }
    
    // 加載數據
    func loadData() {
        isLoading = true
        
        getSleepDashboardDataUseCase.execute(babyId: babyId, timeRange: selectedTimeRange) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                self.errorHandler.handleResult(result) { dashboardData in
                    self.totalSleepDuration = dashboardData.totalSleepDuration
                    self.averageSleepDuration = dashboardData.averageSleepDuration
                    self.sleepQualityDistribution = dashboardData.sleepQualityDistribution
                    self.sleepTimeDistribution = dashboardData.sleepTimeDistribution
                    self.environmentFactorsImpact = dashboardData.environmentFactorsImpact
                    self.sleepRecords = dashboardData.sleepRecords
                }
            }
        }
    }
    
    // 更改時間範圍
    func changeTimeRange(_ timeRange: TimeRange) {
        selectedTimeRange = timeRange
        loadData()
    }
    
    // 格式化總睡眠時間
    var formattedTotalSleepDuration: String {
        formatDuration(totalSleepDuration)
    }
    
    // 格式化平均睡眠時間
    var formattedAverageSleepDuration: String {
        formatDuration(averageSleepDuration)
    }
    
    // 格式化時間
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d小時%02d分鐘", hours, minutes)
        } else {
            return String(format: "%d分鐘", minutes)
        }
    }
    
    // 獲取睡眠質量分布數據
    var sleepQualityChartData: [SleepQualityChartDataPoint] {
        var data: [SleepQualityChartDataPoint] = []
        
        for quality in 1...10 {
            let count = sleepQualityDistribution[quality] ?? 0
            data.append(SleepQualityChartDataPoint(quality: quality, count: count))
        }
        
        return data
    }
    
    // 獲取睡眠時間分布數據
    var sleepTimeChartData: [SleepTimeChartDataPoint] {
        var data: [SleepTimeChartDataPoint] = []
        
        for hour in 0..<24 {
            let duration = sleepTimeDistribution[hour] ?? 0
            data.append(SleepTimeChartDataPoint(hour: hour, duration: duration))
        }
        
        return data
    }
    
    // 獲取環境因素影響數據
    func environmentFactorImpactChartData(for type: EnvironmentFactorType) -> [EnvironmentFactorImpactChartDataPoint] {
        var data: [EnvironmentFactorImpactChartDataPoint] = []
        
        if let impact = environmentFactorsImpact[type] {
            for value in 0...10 {
                let quality = impact[value] ?? 0
                data.append(EnvironmentFactorImpactChartDataPoint(value: value, quality: quality))
            }
        }
        
        return data
    }
}

// 圖表數據結構
struct SleepQualityChartDataPoint: Identifiable {
    let id = UUID()
    let quality: Int
    let count: Int
}

struct SleepTimeChartDataPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let duration: TimeInterval
}

struct EnvironmentFactorImpactChartDataPoint: Identifiable {
    let id = UUID()
    let value: Int
    let quality: Double
}
```

### 2.3 更新依賴注入

最後，更新 DependencyContainer 以提供新的 UseCase：

```swift
// DependencyContainer.swift

class DependencyContainer {
    // 存儲庫
    lazy var babyRepository: BabyRepository = CoreDataBabyRepository(coreDataManager: coreDataManager)
    lazy var sleepRepository: SleepRepository = CoreDataSleepRepository(coreDataManager: coreDataManager)
    lazy var feedingRepository: FeedingRepository = CoreDataFeedingRepository(coreDataManager: coreDataManager)
    lazy var diaperRepository: DiaperRepository = CoreDataDiaperRepository(coreDataManager: coreDataManager)
    lazy var growthRepository: GrowthRepository = CoreDataGrowthRepository(coreDataManager: coreDataManager)
    lazy var milestoneRepository: MilestoneRepository = CoreDataMilestoneRepository(coreDataManager: coreDataManager)
    lazy var activityRepository: ActivityRepository = CoreDataActivityRepository(coreDataManager: coreDataManager)
    
    // 核心服務
    lazy var coreDataManager: CoreDataManager = CoreDataManager()
    lazy var errorHandlingService: ErrorHandlingService = ErrorHandlingService()
    
    // 用例
    lazy var getBabyUseCase: GetBabyUseCase = GetBabyUseCase(babyRepository: babyRepository)
    lazy var saveBabyUseCase: SaveBabyUseCase = SaveBabyUseCase(babyRepository: babyRepository)
    lazy var deleteBabyUseCase: DeleteBabyUseCase = DeleteBabyUseCase(babyRepository: babyRepository)
    
    lazy var getSleepRecordsUseCase: GetSleepRecordsUseCase = GetSleepRecordsUseCase(sleepRepository: sleepRepository)
    lazy var saveSleepRecordUseCase: SaveSleepRecordUseCase = SaveSleepRecordUseCase(sleepRepository: sleepRepository)
    lazy var deleteSleepRecordUseCase: DeleteSleepRecordUseCase = DeleteSleepRecordUseCase(sleepRepository: sleepRepository)
    
    // 新增的 UseCase
    lazy var getSleepDashboardDataUseCase: GetSleepDashboardDataUseCase = GetSleepDashboardDataUseCase(
        sleepRepository: sleepRepository,
        babyRepository: babyRepository
    )
    
    // 其他 UseCase...
    
    // 視圖模型工廠
    func makeBabyViewModel(baby: Baby? = nil) -> BabyViewModel {
        if let baby = baby {
            return BabyViewModel(
                baby: baby,
                saveBabyUseCase: saveBabyUseCase,
                errorHandler: errorHandlingService
            )
        } else {
            return BabyViewModel(
                saveBabyUseCase: saveBabyUseCase,
                errorHandler: errorHandlingService
            )
        }
    }
    
    func makeSleepRecordViewModel(record: SleepRecord? = nil, babyId: UUID? = nil) -> SleepRecordViewModel {
        if let record = record {
            return SleepRecordViewModel(
                record: record,
                saveSleepRecordUseCase: saveSleepRecordUseCase,
                errorHandler: errorHandlingService
            )
        } else if let babyId = babyId {
            return SleepRecordViewModel(
                babyId: babyId,
                saveSleepRecordUseCase: saveSleepRecordUseCase,
                errorHandler: errorHandlingService
            )
        } else {
            fatalError("Either record or babyId must be provided")
        }
    }
    
    // 新增的視圖模型工廠方法
    func makeSleepDashboardViewModel(babyId: UUID) -> SleepDashboardViewModel {
        return SleepDashboardViewModel(
            babyId: babyId,
            getSleepDashboardDataUseCase: getSleepDashboardDataUseCase,
            errorHandler: errorHandlingService
        )
    }
    
    // 其他視圖模型工廠方法...
}
```

### 2.4 更新 UI 實現

更新 SleepDashboardView 使用新的視圖模型：

```swift
// SleepDashboardView.swift

struct SleepDashboardView: View {
    @ObservedObject var viewModel: SleepDashboardViewModel
    @EnvironmentObject var dependencyContainer: DependencyContainer
    
    var body: some View {
        ScrollView {
            VStack(sp
(Content truncated due to size limit. Use line ranges to read in chunks)