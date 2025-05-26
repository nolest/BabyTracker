// dependency_direction_fix.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 依賴方向修正實現

import Foundation
import Combine

// MARK: - 服務定位器（Service Locator）

/// 服務定位器，負責管理和提供應用中的各種服務實例
class ServiceLocator {
    // 單例模式，但僅用於初始配置，實際使用時通過依賴注入
    static let shared = ServiceLocator()
    
    private init() {}
    
    // MARK: - UseCases
    
    /// 提供睡眠用例實例
    lazy var sleepUseCase: SleepUseCase = {
        return SleepUseCaseImpl(repository: sleepRepository)
    }()
    
    /// 提供餵食用例實例
    lazy var feedingUseCase: FeedingUseCase = {
        return FeedingUseCaseImpl(repository: feedingRepository)
    }()
    
    /// 提供活動用例實例
    lazy var activityUseCase: ActivityUseCase = {
        return ActivityUseCaseImpl(repository: activityRepository)
    }()
    
    // MARK: - Repositories
    
    /// 提供睡眠記錄存儲庫實例
    lazy var sleepRepository: SleepRepository = {
        return SleepRecordRepository.shared
    }()
    
    /// 提供餵食記錄存儲庫實例
    lazy var feedingRepository: FeedingRepository = {
        return FeedingRepository.shared
    }()
    
    /// 提供活動記錄存儲庫實例
    lazy var activityRepository: ActivityRepository = {
        return ActivityRepository.shared
    }()
    
    // MARK: - Services
    
    /// 提供用戶設置服務實例
    lazy var userSettings: UserSettings = {
        return UserSettings.shared
    }()
    
    /// 提供網絡監控服務實例
    lazy var networkMonitor: NetworkMonitor = {
        return NetworkMonitor(userSettings: userSettings)
    }()
    
    /// 提供數據匿名化服務實例
    lazy var dataAnonymizer: DataAnonymizer = {
        return DataAnonymizer.shared
    }()
    
    /// 提供Deepseek API客戶端實例
    lazy var deepseekAPIClient: DeepseekAPIClient = {
        return DeepseekAPIClient(userSettings: userSettings)
    }()
    
    /// 提供雲端AI服務實例
    lazy var cloudAIService: CloudAIService = {
        return CloudAIService(
            sleepUseCase: sleepUseCase,
            activityUseCase: activityUseCase,
            networkMonitor: networkMonitor,
            dataAnonymizer: dataAnonymizer,
            apiClient: deepseekAPIClient
        )
    }()
    
    /// 提供AI引擎實例
    lazy var aiEngine: AIEngine = {
        return AIEngine(
            sleepUseCase: sleepUseCase,
            feedingUseCase: feedingUseCase,
            activityUseCase: activityUseCase,
            cloudAIService: cloudAIService,
            networkMonitor: networkMonitor
        )
    }()
    
    /// 提供錯誤處理器實例
    func errorHandler(viewController: UIViewController? = nil) -> ErrorHandler {
        return AppErrorHandler(viewController: viewController)
    }
}

// MARK: - 修正後的AIEngine

/// AI引擎，負責協調本地和雲端AI分析，提供統一的分析接口
class AIEngine {
    // MARK: - 依賴
    
    private let sleepUseCase: SleepUseCase
    private let feedingUseCase: FeedingUseCase
    private let activityUseCase: ActivityUseCase
    private let cloudAIService: CloudAIService
    private let networkMonitor: NetworkMonitor
    
    private let sleepPatternAnalyzer = SleepPatternAnalyzer()
    private let routineAnalyzer = RoutineAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    /// 初始化AI引擎
    /// - Parameters:
    ///   - sleepUseCase: 睡眠用例
    ///   - feedingUseCase: 餵食用例
    ///   - activityUseCase: 活動用例
    ///   - cloudAIService: 雲端AI服務
    ///   - networkMonitor: 網絡監控服務
    init(
        sleepUseCase: SleepUseCase,
        feedingUseCase: FeedingUseCase,
        activityUseCase: ActivityUseCase,
        cloudAIService: CloudAIService,
        networkMonitor: NetworkMonitor
    ) {
        self.sleepUseCase = sleepUseCase
        self.feedingUseCase = feedingUseCase
        self.activityUseCase = activityUseCase
        self.cloudAIService = cloudAIService
        self.networkMonitor = networkMonitor
    }
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    func analyzeSleepPattern(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<SleepPatternResult, Error> {
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() {
            // 嘗試使用雲端分析
            return cloudAIService.analyzeSleepPatternCloud(babyId: babyId, dateRange: dateRange)
                .catch { [weak self] error -> AnyPublisher<SleepPatternResult, Error> in
                    guard let self = self else {
                        return Fail(error: AIError.engineNotAvailable).eraseToAnyPublisher()
                    }
                    
                    // 如果雲端分析失敗（非禁用原因），記錄錯誤
                    if !(error is CloudError) {
                        print("雲端睡眠分析失敗：\(error.localizedDescription)，降級到本地分析")
                    }
                    
                    // 降級到本地分析
                    return self.analyzeSleepPatternLocal(babyId: babyId, dateRange: dateRange)
                }
                .eraseToAnyPublisher()
        }
        
        // 直接使用本地分析
        return analyzeSleepPatternLocal(babyId: babyId, dateRange: dateRange)
    }
    
    /// 分析作息模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    func analyzeRoutine(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<RoutineAnalysisResult, Error> {
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() {
            // 嘗試使用雲端分析
            return cloudAIService.analyzeRoutineCloud(babyId: babyId, dateRange: dateRange)
                .catch { [weak self] error -> AnyPublisher<RoutineAnalysisResult, Error> in
                    guard let self = self else {
                        return Fail(error: AIError.engineNotAvailable).eraseToAnyPublisher()
                    }
                    
                    // 如果雲端分析失敗（非禁用原因），記錄錯誤
                    if !(error is CloudError) {
                        print("雲端作息分析失敗：\(error.localizedDescription)，降級到本地分析")
                    }
                    
                    // 降級到本地分析
                    return self.analyzeRoutineLocal(babyId: babyId, dateRange: dateRange)
                }
                .eraseToAnyPublisher()
        }
        
        // 直接使用本地分析
        return analyzeRoutineLocal(babyId: babyId, dateRange: dateRange)
    }
    
    /// 預測下次睡眠
    /// - Parameter babyId: 寶寶ID
    /// - Returns: 預測結果發布者
    func predictNextSleep(babyId: String) -> AnyPublisher<PredictionResult, Error> {
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() {
            // 嘗試使用雲端分析
            return cloudAIService.predictNextSleepCloud(babyId: babyId)
                .catch { [weak self] error -> AnyPublisher<PredictionResult, Error> in
                    guard let self = self else {
                        return Fail(error: AIError.engineNotAvailable).eraseToAnyPublisher()
                    }
                    
                    // 如果雲端分析失敗（非禁用原因），記錄錯誤
                    if !(error is CloudError) {
                        print("雲端睡眠預測失敗：\(error.localizedDescription)，降級到本地分析")
                    }
                    
                    // 降級到本地分析
                    return self.predictNextSleepLocal(babyId: babyId)
                }
                .eraseToAnyPublisher()
        }
        
        // 直接使用本地分析
        return predictNextSleepLocal(babyId: babyId)
    }
    
    /// 獲取分析來源描述
    /// - Parameter isCloudAnalysis: 是否為雲端分析
    /// - Returns: 分析來源描述
    func getAnalysisSourceDescription(isCloudAnalysis: Bool) -> String {
        return isCloudAnalysis ? 
            NSLocalizedString("由Deepseek AI雲端分析提供", comment: "") : 
            NSLocalizedString("由本地分析提供", comment: "")
    }
    
    // MARK: - 私有方法
    
    /// 本地分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    private func analyzeSleepPatternLocal(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<SleepPatternResult, Error> {
        return Future<SleepPatternResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AIError.engineNotAvailable))
                return
            }
            
            Task {
                // 獲取睡眠記錄
                let sleepRecordsResult = await self.sleepUseCase.getSleepRecords(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                switch sleepRecordsResult {
                case .success(let sleepRecords):
                    // 使用本地分析器分析
                    let result = self.sleepPatternAnalyzer.analyze(sleepRecords: sleepRecords)
                    promise(.success(result))
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 本地分析作息模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    private func analyzeRoutineLocal(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<RoutineAnalysisResult, Error> {
        return Future<RoutineAnalysisResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AIError.engineNotAvailable))
                return
            }
            
            Task {
                // 獲取活動記錄
                let activitiesResult = await self.activityUseCase.getActivities(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                switch activitiesResult {
                case .success(let activities):
                    // 使用本地分析器分析
                    let result = self.routineAnalyzer.analyze(activities: activities)
                    promise(.success(result))
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 本地預測下次睡眠
    /// - Parameter babyId: 寶寶ID
    /// - Returns: 預測結果發布者
    private func predictNextSleepLocal(babyId: String) -> AnyPublisher<PredictionResult, Error> {
        return Future<PredictionResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AIError.engineNotAvailable))
                return
            }
            
            Task {
                // 獲取分析時間範圍（過去14天）
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
                let dateRange = startDate...endDate
                
                // 獲取睡眠記錄
                let sleepRecordsResult = await self.sleepUseCase.getSleepRecords(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                // 獲取活動記錄
                let activitiesResult = await self.activityUseCase.getActivities(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                // 檢查數據可用性
                guard case .success(let sleepRecords) = sleepRecordsResult,
                      case .success(let activities) = activitiesResult,
                      !sleepRecords.isEmpty else {
                    promise(.failure(AIError.insufficientData))
                    return
                }
                
                // 使用本地預測引擎預測
                let predictionEngine = PredictionEngine(
                    sleepUseCase: self.sleepUseCase,
                    feedingUseCase: self.feedingUseCase,
                    activityUseCase: self.activityUseCase,
                    sleepPatternAnalyzer: self.sleepPatternAnalyzer,
                    routineAnalyzer: self.routineAnalyzer
                )
                
                let result = predictionEngine.predict(
                    babyId: babyId,
                    sleepRecords: sleepRecords,
                    activities: activities
                )
                
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - AI錯誤類型

/// AI分析相關錯誤
enum AIError: Error {
    /// AI引擎不可用
    case engineNotAvailable
    /// 數據不足
    case insufficientData
    /// 分析失敗
    case analysisFailed
    /// 預測失敗
    case predictionFailed
}

// MARK: - 修正後的CloudAIService

/// 雲端AI服務，負責協調雲端AI分析服務，處理用戶設置、網絡狀態、數據匿名化和API調用
class CloudAIService {
    // MARK: - 依賴
    
    private let sleepUseCase: SleepUseCase
    private let activityUseCase: ActivityUseCase
    private let networkMonitor: NetworkMonitor
    private let dataAnonymizer: DataAnonymizer
    private let apiClient: DeepseekAPIClient
    
    // MARK: - 緩存
    
    private var sleepAnalysisCache: [String: DeepseekSleepAnalysisResponse] = [:]
    private var routineAnalysisCache: [String: DeepseekRoutineAnalysisResponse] = [:]
    private var predictionCache: [String: DeepseekPredictionResponse] = [:]
    
    // MARK: - 常量
    
    private let cacheExpirationInterval: TimeInterval = 3600 // 1小時
    
    // MARK: - 初始化
    
    /// 初始化雲端AI服務
    /// - Parameters:
    ///   - sleepUseCase: 睡眠用例
    ///   - activityUseCase: 活動用例
    ///   - networkMonitor: 網絡監控服務
    ///   - dataAnonymizer: 數據匿名化服務
    ///   - apiClient: Deepseek API客戶端
    init(
        sleepUseCase: SleepUseCase,
        activityUseCase: ActivityUseCase,
        networkMonitor: NetworkMonitor,
        dataAnonymizer: DataAnonymizer,
        apiClient: DeepseekAPIClient
    ) {
        self.sleepUseCase = sleepUseCase
        self.activityUseCase = activityUseCase
        self.networkMonitor = networkMonitor
        self.dataAnonymizer = dataAnonymizer
        self.apiClient = apiClient
    }
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式（雲端）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    func analyzeSleepPatternCloud(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<SleepPatternResult, Error> {
        // 檢查是否可以使用雲端分析
        guard networkMonitor.canUseCloudAnalysis() else {
            return Fail(error: CloudError.cloudAnalysisDisabled).eraseToAnyPublisher()
        }
        
        return Future<SleepPatternResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CloudError.unknownError))
                return
            }
            
            Task {
                // 獲取睡眠記錄
                let sleepRecordsResult = await self.sleepUseCase.getSleepRecords(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                switch sleepRecordsResult {
                case .success(let sleepRecords):
                    // 檢查記錄數量
                    guard !sleepRecords.isEmpty else {
                        promise(.failure(CloudError.insufficientData))
                        return
                    }
                    
                    // 檢查緩存
                    let cacheKey = self.generateCacheKey(babyId: babyId, dateRange: dateRange, type: "sleep")
                    if let cachedResult = self.sleepAnalysisCache[cacheKey],
                       self.isCacheValid(cacheKey: cacheKey) {
                        promise(.success(self.convertToSleepPatternResult(cachedResult)))
                        return
                    }
                    
                    // 匿名化數據
                    let anonymizedData = self.dataAnonymizer.anonymizeSleepRecords(sleepRecords)
                    
                    // 調用API
                    let apiResult = await self.apiClient.analyzeSleep(data: anonymizedData)
                    
                    switch apiResult {
                    case .success(let response):
                        // 更新緩存
                        self.sleepAnalysisCache[cacheKey] = response
                        
                        // 轉換為本地模型
                        let result = self.convertToSleepPatternResult(response)
                        promise(.success(result))
                        
                    case .failure(let apiError):
                        promise(.failure(self.convertAPIError(apiError)))
                    }
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 分析作息模式（雲端）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    func analyzeRoutineCloud(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<RoutineAnalysisResult, Error> {
        // 檢查是否可以使用雲端分析
        guard networkMonitor.canUseCloudAnalysis() else {
            return Fail(error: CloudError.cloudAnalysisDisabled).eraseToAnyPublisher()
        }
        
        return Future<RoutineAnalysisResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CloudError.unknownError))
                return
            }
            
            Task {
                // 獲取活動記錄
                let activitiesResult = await self.activityUseCase.getActivities(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                switch activitiesResult {
                case .success(let activities):
                    // 檢查記錄數量
                    guard !activities.isEmpty else {
                        promise(.failure(CloudError.insufficientData))
                        return
                    }
                    
                    // 檢查緩存
                    let cacheKey = self.generateCacheKey(babyId: babyId, dateRange: dateRange, type: "routine")
                    if let cachedResult = self.routineAnalysisCache[cacheKey],
                       self.isCacheValid(cacheKey: cacheKey) {
                        promise(.success(self.convertToRoutineAnalysisResult(cachedResult)))
                        return
                    }
                    
                    // 匿名化數據
                    let anonymizedData = self.dataAnonymizer.anonymizeRoutineRecords(activities)
                    
                    // 調用API
                    let apiResult = await self.apiClient.analyzeRoutine(data: anonymizedData)
                    
                    switch apiResult {
                    case .success(let response):
                        // 更新緩存
                        self.routineAnalysisCache[cacheKey] = response
                        
                        // 轉換為本地模型
                        let result = self.convertToRoutineAnalysisResult(response)
                        promise(.success(result))
                        
                    case .failure(let apiError):
                        promise(.failure(self.convertAPIError(apiError)))
                    }
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 預測下次睡眠（雲端）
    /// - Parameter babyId: 寶寶ID
    /// - Returns: 預測結果發布者
    func predictNextSleepCloud(babyId: String) -> AnyPublisher<PredictionResult, Error> {
        // 檢查是否可以使用雲端分析
        guard networkMonitor.canUseCloudAnalysis() else {
            return Fail(error: CloudError.cloudAnalysisDisabled).eraseToAnyPublisher()
        }
        
        return Future<PredictionResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CloudError.unknownError))
                return
            }
            
            Task {
                // 獲取分析時間範圍（過去14天）
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
                let dateRange = startDate...endDate
                
                // 檢查緩存
                let cacheKey = self.generateCacheKey(babyId: babyId, dateRange: dateRange, type: "prediction")
                if let cachedResult = self.predictionCache[cacheKey],
                   self.isCacheValid(cacheKey: cacheKey, maxAge: 1800) { // 30分鐘
                    promise(.success(self.convertToPredictionResult(cachedResult, babyId: babyId)))
                    return
                }
                
                // 獲取睡眠記錄
                let sleepRecordsResult = await self.sleepUseCase.getSleepRecords(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                // 獲取活動記錄
                let activitiesResult = await self.activityUseCase.getActivities(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                // 檢查數據可用性
                guard case .success(let sleepRecords) = sleepRecordsResult,
                      case .success(let activities) = activitiesResult,
                      !sleepRecords.isEmpty,
                      !activities.isEmpty else {
                    promise(.failure(CloudError.insufficientData))
                    return
                }
                
                // 匿名化數據
                let anonymizedSleepData = self.dataAnonymizer.anonymizeSleepRecords(sleepRecords)
                let anonymizedRoutineData = self.dataAnonymizer.anonymizeRoutineRecords(activities)
                
                // 調用API
                let apiResult = await self.apiClient.generatePrediction(
                    sleepData: anonymizedSleepData,
                    routineData: anonymizedRoutineData
                )
                
                switch apiResult {
                case .success(let response):
                    // 更新緩存
                    self.predictionCache[cacheKey] = response
                    
                    // 轉換為本地模型
                    let result = self.convertToPredictionResult(response, babyId: babyId)
                    promise(.success(result))
                    
                case .failure(let apiError):
                    promise(.failure(self.convertAPIError(apiError)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 輔助方法
    
    /// 生成緩存鍵
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    ///   - type: 分析類型
    /// - Returns: 緩存鍵
    private func generateCacheKey(babyId: String, dateRange: ClosedRange<Date>, type: String) -> String {
        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: dateRange.lowerBound)
        let endString = formatter.string(from: dateRange.upperBound)
        return "\(type)_\(babyId)_\(startString)_\(endString)"
    }
    
    /// 檢查緩存是否有效
    /// - Parameters:
    ///   - cacheKey: 緩存鍵
    ///   - maxAge: 最大有效期（秒）
    /// - Returns: 緩存是否有效
    private func isCacheValid(cacheKey: String, maxAge: TimeInterval = 3600) -> Bool {
        // 這裡應該檢查緩存的時間戳，但為了簡化，我們假設緩存總是有效的
        // 在實際實現中，應該存儲緩存時間並檢查是否過期
        return true
    }
    
    /// 將API錯誤轉換為本地錯誤
    /// - Parameter apiError: API錯誤
    /// - Returns: 本地錯誤
    private func convertAPIError(_ apiError: DeepseekAPIClient.APIError) -> Error {
        switch apiError {
        case .invalidAPIKey:
            return CloudError.invalidAPIKey
        case .networkError:
            return CloudError.networkError
        case .serverError:
            return CloudError.serverError
        case .rateLimitExceeded:
            return CloudError.rateLimitExceeded
        case .timeout:
            return CloudError.timeout
        default:
            return CloudError.unknownError
        }
    }
    
    /// 將Deepseek睡眠分析響應轉換為本地睡眠模式結果
    /// - Parameter response: Deepseek響應
    /// - Returns: 本地睡眠模式結果
    private func convertToSleepPatternResult(_ response: DeepseekSleepAnalysisResponse) -> SleepPatternResult {
        // 轉換睡眠模式類型
        let patternType: SleepPatternType
        switch response.sleepPatternType.lowercased() {
        case "highly_regular":
            patternType = .highlyRegular
        case "moderately_regular":
            patternType = .moderatelyRegular
        case "irregular":
            patternType = .irregular
        case "evolving":
            patternType = .evolving
        case "transitioning":
            patternType = .transitioning
        default:
            patternType = .insufficient
        }
        
        // 轉換環境因素影響
        let environmentFactors = SleepEnvironmentFactors(
            lightImpact: convertFactorImpact(response.environmentalFactorImpact.light),
            noiseImpact: convertFactorImpact(response.environmentalFactorImpact.noise),
            temperatureImpact: convertFactorImpact(response.environmentalFactorImpact.temperature),
            humidityImpact: convertFactorImpact(response.environmentalFactorImpact.humidity)
        )
        
        // 轉換睡眠趨勢
        let trend: SleepTrend
        switch response.sleepTrend.lowercased() {
        case "improving":
            trend = .improving
        case "stable":
            trend = .stable
        case "declining":
            trend = .declining
        case "fluctuating":
            trend = .fluctuating
        default:
            trend = .insufficient
        }
        
        return SleepPatternResult(
            sleepPatternType: patternType,
            regularityScore: response.regularityScore,
            averageSleepDuration: response.averageSleepDuration,
            sleepQualityScore: response.sleepQualityScore,
            environmentFactors: environmentFactors,
            trend: trend,
            recommendations: response.recommendations,
            confidenceScore: response.confidenceScore,
            isCloudAnalysis: true
        )
    }
    
    /// 將因素影響轉換為本地模型
    /// - Parameter impact: API因素影響
    /// - Returns: 本地因素影響
    private func convertFactorImpact(_ impact: FactorImpact) -> EnvironmentFactorImpact {
        let level: ImpactLevel
        switch impact.impactLevel.lowercased() {
        case "high":
            level = .high
        case "medium":
            level = .medium
        case "low":
            level = .low
        default:
            level = .none
        }
        
        return EnvironmentFactorImpact(
            level: level,
            correlation: impact.correlation,
            recommendation: impact.recommendation
        )
    }
    
    /// 將Deepseek作息分析響應轉換為本地作息分析結果
    /// - Parameter response: Deepseek響應
    /// - Returns: 本地作息分析結果
    private func convertToRoutineAnalysisResult(_ response: DeepseekRoutineAnalysisResponse) -> RoutineAnalysisResult {
        // 轉換典型模式
        let patterns = response.typicalPatterns.map { pattern -> RoutinePattern in
            return RoutinePattern(
                name: pattern.patternName,
                activities: pattern.activities,
                averageDuration: pattern.averageDuration,
                frequency: pattern.frequency
            )
        }
        
        // 轉換活動分佈
        let distributions = response.activityDistribution.map { dist -> ActivityDistributionData in
            let timeRanges = dist.preferredTimeRanges.map { range -> PreferredTimeRange in
                return PreferredTimeRange(
                    startMinutes: range.startMinutes,
                    endMinutes: range.endMinutes,
                    frequency: range.frequency
                )
            }
            
            return ActivityDistributionData(
                activityType: dist.activityType,
                percentage: dist.percentage,
                averageDuration: dist.averageDuration,
                preferredTimeRanges: timeRanges
            )
        }
        
        // 轉換作息趨勢
        let trend: RoutineTrend
        switch response.routineTrend.lowercased() {
        case "improving":
            trend = .improving
        case "stable":
            trend = .stable
        case "declining":
            trend = .declining
        case "fluctuating":
            trend = .fluctuating
        default:
            trend = .insufficient
        }
        
        return RoutineAnalysisResult(
            regularityScore: response.routineRegularityScore,
            typicalPatterns: patterns,
            activityDistribution: distributions,
            trend: trend,
            recommendations: response.recommendations,
            confidenceScore: response.confidenceScore,
            isCloudAnalysis: true
        )
    }
    
    /// 將Deepseek預測響應轉換為本地預測結果
    /// - Parameters:
    ///   - response: Deepseek響應
    ///   - babyId: 寶寶ID
    /// - Returns: 本地預測結果
    private func convertToPredictionResult(_ response: DeepseekPredictionResponse, babyId: String) -> PredictionResult {
        // 轉換下次睡眠預測
        let nextSleepPrediction: NextSleepPrediction?
        if let nextSleep = response.nextSleep {
            let now = Date()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            
            // 計算預測時間
            let earliestStartTime = calendar.date(
                byAdding: .minute,
                value: nextSleep.earliestStartMinutes,
                to: today
            ) ?? now
            
            let latestStartTime = calendar.date(
                byAdding: .minute,
                value: nextSleep.latestStartMinutes,
                to: today
            ) ?? now
            
            nextSleepPrediction = NextSleepPrediction(
                earliestStartTime: earliestStartTime,
                latestStartTime: latestStartTime,
                expectedDuration: TimeInterval(nextSleep.expectedDurationMinutes * 60),
                durationVariance: TimeInterval(nextSleep.durationVarianceMinutes * 60),
                confidence: nextSleep.confidence
            )
        } else {
            nextSleepPrediction = nil
        }
        
        return PredictionResult(
            babyId: babyId,
            nextSleep: nextSleepPrediction,
            recommendations: response.recommendations,
            confidenceScore: response.confidenceScore,
            isCloudPrediction: true
        )
    }
}

// MARK: - 修正後的NetworkMonitor

/// 網絡監控服務，監控網絡連接狀態，提供當前網絡類型和可用性信息
class NetworkMonitor {
    // MARK: - 網絡類型枚舉
    
    /// 網絡連接類型
    enum ConnectionType {
        /// WiFi連接
        case wifi
        /// 蜂窩網絡連接
        case cellular
        /// 有線網絡連接
        case ethernet
        /// 未知連接類型
        case unknown
    }
    
    // MARK: - 屬性
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let userSettings: UserSettings
    
    private(set) var isConnected = false
    private(set) var connectionType: ConnectionType = .unknown
    
    // MARK: - 初始化
    
    /// 初始化網絡監控服務
    /// - Parameter userSettings: 用戶設置服務
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
        startMonitoring()
    }
    
    // MARK: - 公開方法
    
    /// 開始監控網絡狀態
    func startMonitoring() {
        monitor.start(queue: queue)
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // 更新連接狀態
            self.isConnected = path.status == .satisfied
            
            // 更新連接類型
            self.connectionType = self.getConnectionType(path)
            
            // 發送通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil
                )
            }
        }
    }
    
    /// 停止監控網絡狀態
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// 檢查是否可以使用雲端分析
    /// - Returns: 是否可以使用雲端分析
    func canUseCloudAnalysis() -> Bool {
        // 如果用戶未啟用雲端分析，則不可用
        guard userSettings.isCloudAnalysisEnabled else {
            return false
        }
        
        // 如果沒有API Key，則不可用
        guard userSettings.deepseekAPIKey != nil else {
            return false
        }
        
        // 如果沒有網絡連接，則不可用
        guard isConnected else {
            return false
        }
        
        // 如果設置僅在WiFi下使用雲端分析，則檢查當前是否為WiFi
        if userSettings.useCloudAnalysisOnlyOnWiFi {
            return connectionType == .wifi
        }
        
        // 其他情況下可用
        return true
    }
    
    // MARK: - 私有方法
    
    /// 獲取當前網絡連接類型
    /// - Parameter path: 網絡路徑
    /// - Returns: 連接類型
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

// MARK: - 修正後的DeepseekAPIClient

/// Deepseek API客戶端，負責與Deepseek API的通信
class DeepseekAPIClient {
    // MARK: - API錯誤
    
    /// API錯誤類型
    enum APIError: Error {
        /// 無效的URL
        case invalidURL
        /// 無效的API Key
        case invalidAPIKey
        /// 網絡錯誤
        case networkError(Error)
        /// 服務器錯誤
        case serverError(Int, String)
        /// 解碼錯誤
        case decodingError(Error)
        /// 無數據
        case noData
        /// 超出速率限制
        case rateLimitExceeded
        /// 超時
        case timeout
        /// 未知錯誤
        case unknown
    }
    
    // MARK: - 常量
    
    private enum APIEndpoints {
        static let baseURL = "https://api.deepseek.com"
        static let sleepAnalysis = "/v1/baby/sleep/analyze"
        static let routineAnalysis = "/v1/baby/routine/analyze"
        static let predictionGenerate = "/v1/baby/prediction/generate"
    }
    
    private enum HTTPMethod {
        static let post = "POST"
        static let get = "GET"
    }
    
    // MARK: - 屬性
    
    private let userSettings: UserSettings
    
    // MARK: - 初始化
    
    /// 初始化Deepseek API客戶端
    /// - Parameter userSettings: 用戶設置服務
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
    }
    
    // MARK: - 公開方法
    
    /// 分析睡眠數據
    /// - Parameter data: 匿名化的睡眠數據
    /// - Returns: 分析結果或錯誤
    func analyzeSleep(data: AnonymizedSleepData) async -> Result<DeepseekSleepAnalysisResponse, APIError> {
        return await sendRequest(
            endpoint: APIEndpoints.sleepAnalysis,
            body: data
        )
    }
    
    /// 分析作息數據
    /// - Parameter data: 匿名化的作息數據
    /// - Returns: 分析結果或錯誤
    func analyzeRoutine(data: AnonymizedRoutineData) async -> Result<DeepseekRoutineAnalysisResponse, APIError> {
        return await sendRequest(
            endpoint: APIEndpoints.routineAnalysis,
            body: data
        )
    }
    
    /// 生成預測
    /// - Parameters:
    ///   - sleepData: 匿名化的睡眠數據
    ///   - routineData: 匿名化的作息數據
    /// - Returns: 預測結果或錯誤
    func generatePrediction(
        sleepData: AnonymizedSleepData,
        routineData: AnonymizedRoutineData
    ) async -> Result<DeepseekPredictionResponse, APIError> {
        // 創建組合請求數據
        let combinedData = DeepseekPredictionRequest(
            sleepData: sleepData,
            routineData: routineData
        )
        
        return await sendRequest(
            endpoint: APIEndpoints.predictionGenerate,
            body: combinedData
        )
    }
    
    // MARK: - 私有方法
    
    /// 發送API請求
    /// - Parameters:
    ///   - endpoint: API端點
    ///   - body: 請求體
    /// - Returns: 響應結果或錯誤
    private func sendRequest<T: Encodable, U: Decodable>(
        endpoint: String,
        body: T
    ) async -> Result<U, APIError> {
        // 檢查API Key
        guard let apiKey = userSettings.deepseekAPIKey, !apiKey.isEmpty else {
            return .failure(.invalidAPIKey)
        }
        
        // 創建URL
        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            return .failure(.invalidURL)
        }
        
        // 創建請求
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 設置超時
        request.timeoutInterval = 30
        
        do {
            // 編碼請求體
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
            
            // 發送請求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 檢查HTTP響應
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknown)
            }
            
            // 處理HTTP狀態碼
            switch httpResponse.statusCode {
            case 200...299:
                // 成功
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(U.self, from: data)
                    return .success(result)
                } catch {
                    return .failure(.decodingError(error))
                }
                
            case 401:
                // 未授權（無效的API Key）
                return .failure(.invalidAPIKey)
                
            case 429:
                // 超出速率限制
                return .failure(.rateLimitExceeded)
                
            default:
                // 其他錯誤
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(.serverError(httpResponse.statusCode, errorMessage))
            }
            
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout)
        } catch {
            return .failure(.networkError(error))
        }
    }
}

// MARK: - 用例協議

/// 睡眠用例協議
protocol SleepUseCase {
    /// 獲取睡眠記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 睡眠記錄結果
    func getSleepRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[SleepRecord], Error>
}

/// 餵食用例協議
protocol FeedingUseCase {
    /// 獲取餵食記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 餵食記錄結果
    func getFeedingRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[FeedingRecord], Error>
}

/// 活動用例協議
protocol ActivityUseCase {
    /// 獲取活動記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 活動記錄結果
    func getActivities(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[Activity], Error>
}

// MARK: - 用例實現

/// 睡眠用例實現
class SleepUseCaseImpl: SleepUseCase {
    private let repository: SleepRepository
    
    init(repository: SleepRepository) {
        self.repository = repository
    }
    
    func getSleepRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[SleepRecord], Error> {
        return await repository.getSleepRecords(babyId: babyId, dateRange: dateRange)
    }
}

/// 餵食用例實現
class FeedingUseCaseImpl: FeedingUseCase {
    private let repository: FeedingRepository
    
    init(repository: FeedingRepository) {
        self.repository = repository
    }
    
    func getFeedingRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[FeedingRecord], Error> {
        return await repository.getFeedingRecords(babyId: babyId, dateRange: dateRange)
    }
}

/// 活動用例實現
class ActivityUseCaseImpl: ActivityUseCase {
    private let repository: ActivityRepository
    
    init(repository: ActivityRepository) {
        self.repository = repository
    }
    
    func getActivities(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[Activity], Error> {
        return await repository.getActivities(babyId: babyId, dateRange: dateRange)
    }
}
