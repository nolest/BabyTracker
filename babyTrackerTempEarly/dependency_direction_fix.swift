// dependency_direction_fix.swift
// 寶寶生活記錄專業版（Baby Tracker）- 依賴方向修復實現

import Foundation
import Combine

// MARK: - 定義協議

/// 睡眠用例協議
protocol SleepUseCase {
    func getSleepRecords(for babyId: UUID) -> AnyPublisher<[SleepRecord], AppError>
    func getSleepStatistics(for babyId: UUID, timeRange: TimeRange) -> AnyPublisher<SleepStatistics, AppError>
}

/// 作息用例協議
protocol RoutineUseCase {
    func getActivities(for babyId: UUID, timeRange: TimeRange) -> AnyPublisher<[Activity], AppError>
    func getRoutineStatistics(for babyId: UUID, timeRange: TimeRange) -> AnyPublisher<RoutineStatistics, AppError>
}

/// AI分析服務協議
protocol AIAnalysisService {
    func analyzeSleepPattern(for babyId: UUID, with settings: AnalysisSettings) -> AnyPublisher<SleepPatternAnalysisResult, AppError>
    func analyzeRoutine(for babyId: UUID, with settings: AnalysisSettings) -> AnyPublisher<RoutineAnalysisResult, AppError>
    func predictNextSleep(for babyId: UUID) -> AnyPublisher<SleepPrediction, AppError>
}

/// Deepseek API客戶端協議
protocol DeepseekClientProtocol {
    func analyzeSleepData(_ data: AnonymizedSleepData) -> AnyPublisher<DeepseekAnalysisResponse, AppError>
    func analyzeRoutineData(_ data: AnonymizedRoutineData) -> AnyPublisher<DeepseekAnalysisResponse, AppError>
    func predictNextActivity(_ data: AnonymizedActivityData) -> AnyPublisher<DeepseekPredictionResponse, AppError>
}

// MARK: - 修復後的AIEngine實現

/// AI引擎 - 修復後的實現
class AIEngine: AIAnalysisService {
    private let sleepUseCase: SleepUseCase
    private let routineUseCase: RoutineUseCase
    private let deepseekClient: DeepseekClientProtocol
    private let networkMonitor: NetworkMonitor
    private let settingsService: SettingsService
    
    // 進度報告回調
    var onProgressUpdate: ((AnalysisProgress) -> Void)?
    
    init(sleepUseCase: SleepUseCase, 
         routineUseCase: RoutineUseCase,
         deepseekClient: DeepseekClientProtocol,
         networkMonitor: NetworkMonitor,
         settingsService: SettingsService) {
        self.sleepUseCase = sleepUseCase
        self.routineUseCase = routineUseCase
        self.deepseekClient = deepseekClient
        self.networkMonitor = networkMonitor
        self.settingsService = settingsService
    }
    
    // MARK: - AIAnalysisService 實現
    
    func analyzeSleepPattern(for babyId: UUID, with settings: AnalysisSettings) -> AnyPublisher<SleepPatternAnalysisResult, AppError> {
        // 報告進度：數據加載
        self.onProgressUpdate?(AnalysisProgress(stage: .dataLoading, progress: 0.0))
        
        // 從UseCase獲取數據，而非直接從Repository
        return sleepUseCase.getSleepRecords(for: babyId)
            .handleEvents(receiveOutput: { [weak self] _ in
                // 報告進度：數據加載完成
                self?.onProgressUpdate?(AnalysisProgress(stage: .dataLoading, progress: 1.0))
                // 報告進度：數據預處理
                self?.onProgressUpdate?(AnalysisProgress(stage: .preprocessing, progress: 0.0))
            })
            .flatMap { [weak self] records -> AnyPublisher<SleepPatternAnalysisResult, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.analysis(.engineNotAvailable)).eraseToAnyPublisher()
                }
                
                // 報告進度：數據預處理完成
                self.onProgressUpdate?(AnalysisProgress(stage: .preprocessing, progress: 1.0))
                
                // 檢查是否應該使用雲端分析
                let shouldUseCloudAnalysis = !settings.preferLocalAnalysis && 
                                            self.networkMonitor.isConnected &&
                                            !APIKeyManager.shared.isRateLimited()
                
                if shouldUseCloudAnalysis {
                    // 報告進度：模式分析
                    self.onProgressUpdate?(AnalysisProgress(stage: .patternAnalysis, progress: 0.0, message: "使用雲端AI進行深度分析"))
                    
                    // 準備匿名化數據
                    let anonymizedData = self.prepareAnonymizedSleepData(records)
                    
                    // 使用Deepseek客戶端進行雲端分析
                    return self.deepseekClient.analyzeSleepData(anonymizedData)
                        .handleEvents(receiveOutput: { [weak self] _ in
                            // 報告進度：模式分析完成
                            self?.onProgressUpdate?(AnalysisProgress(stage: .patternAnalysis, progress: 1.0))
                            // 報告進度：環境因素分析
                            self?.onProgressUpdate?(AnalysisProgress(stage: .environmentalAnalysis, progress: 0.0))
                        })
                        .map { response in
                            // 將Deepseek響應轉換為分析結果
                            return self.convertToSleepAnalysisResult(response, babyId: babyId, source: .cloud)
                        }
                        .handleEvents(receiveOutput: { [weak self] _ in
                            // 報告進度：環境因素分析完成
                            self?.onProgressUpdate?(AnalysisProgress(stage: .environmentalAnalysis, progress: 1.0))
                            // 報告進度：質量評估
                            self?.onProgressUpdate?(AnalysisProgress(stage: .qualityEvaluation, progress: 0.0))
                        })
                        .eraseToAnyPublisher()
                } else {
                    // 報告進度：模式分析
                    self.onProgressUpdate?(AnalysisProgress(stage: .patternAnalysis, progress: 0.0, message: "使用本地分析"))
                    
                    // 使用本地分析
                    return self.performLocalSleepAnalysis(records, babyId: babyId)
                        .eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // 報告進度：質量評估完成
                self?.onProgressUpdate?(AnalysisProgress(stage: .qualityEvaluation, progress: 1.0))
                // 報告進度：生成建議
                self?.onProgressUpdate?(AnalysisProgress(stage: .recommendationGeneration, progress: 0.0))
            })
            .map { [weak self] result in
                // 生成建議
                var resultWithRecommendations = result
                resultWithRecommendations.recommendations = self?.generateSleepRecommendations(for: result) ?? []
                return resultWithRecommendations
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // 報告進度：生成建議完成
                self?.onProgressUpdate?(AnalysisProgress(stage: .recommendationGeneration, progress: 1.0))
                // 報告進度：完成分析
                self?.onProgressUpdate?(AnalysisProgress(stage: .finalizing, progress: 0.0))
            })
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.global())
            .handleEvents(receiveOutput: { [weak self] _ in
                // 報告進度：完成分析
                self?.onProgressUpdate?(AnalysisProgress(stage: .finalizing, progress: 1.0))
            })
            .eraseToAnyPublisher()
    }
    
    func analyzeRoutine(for babyId: UUID, with settings: AnalysisSettings) -> AnyPublisher<RoutineAnalysisResult, AppError> {
        // 類似的實現，從UseCase獲取數據
        return routineUseCase.getActivities(for: babyId, timeRange: settings.routineAnalysisSettings.historicalDataRange)
            .flatMap { [weak self] activities -> AnyPublisher<RoutineAnalysisResult, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.analysis(.engineNotAvailable)).eraseToAnyPublisher()
                }
                
                // 實現類似於睡眠分析的邏輯...
                return Just(RoutineAnalysisResult(id: UUID(), babyId: babyId, analysisDate: Date(), regularityScore: 0.8, typicalPatterns: [], activityDistribution: [:], recommendations: [], analysisSource: .local))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func predictNextSleep(for babyId: UUID) -> AnyPublisher<SleepPrediction, AppError> {
        // 從UseCase獲取數據
        return sleepUseCase.getSleepRecords(for: babyId)
            .flatMap { [weak self] records -> AnyPublisher<SleepPrediction, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.analysis(.engineNotAvailable)).eraseToAnyPublisher()
                }
                
                // 實現預測邏輯...
                return Just(SleepPrediction(id: UUID(), babyId: babyId, predictedStartTime: Date().addingTimeInterval(4 * 3600), predictedDuration: 7200, confidence: 0.75, predictionSource: .local))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 輔助方法
    
    private func prepareAnonymizedSleepData(_ records: [SleepRecord]) -> AnonymizedSleepData {
        // 實現數據匿名化...
        return AnonymizedSleepData(deviceId: "anonymous", records: records.map { record in
            return AnonymizedSleepRecord(
                duration: record.duration,
                startTime: record.startTime.timeIntervalSince1970,
                quality: record.quality.rawValue,
                interruptions: record.interruptions.count,
                environmentalFactors: record.environmentalFactors.map { factor in
                    return AnonymizedEnvironmentalFactor(
                        type: factor.type.rawValue,
                        value: factor.value
                    )
                }
            )
        })
    }
    
    private func convertToSleepAnalysisResult(_ response: DeepseekAnalysisResponse, babyId: UUID, source: AnalysisSource) -> SleepPatternAnalysisResult {
        // 實現轉換邏輯...
        return SleepPatternAnalysisResult(
            id: UUID(),
            babyId: babyId,
            analysisDate: Date(),
            sleepEfficiency: response.efficiency ?? 0.75,
            sleepQualityScore: response.qualityScore ?? 0.8,
            averageSleepDuration: response.averageDuration ?? 28800,
            sleepCycleCount: response.cycleCount ?? 4,
            environmentalFactors: [],
            recommendations: [],
            analysisSource: source
        )
    }
    
    private func performLocalSleepAnalysis(_ records: [SleepRecord], babyId: UUID) -> AnyPublisher<SleepPatternAnalysisResult, AppError> {
        // 實現本地分析邏輯...
        return Just(SleepPatternAnalysisResult(
            id: UUID(),
            babyId: babyId,
            analysisDate: Date(),
            sleepEfficiency: 0.7,
            sleepQualityScore: 0.75,
            averageSleepDuration: 25200,
            sleepCycleCount: 3,
            environmentalFactors: [],
            recommendations: [],
            analysisSource: .local
        ))
        .setFailureType(to: AppError.self)
        .eraseToAnyPublisher()
    }
    
    private func generateSleepRecommendations(for result: SleepPatternAnalysisResult) -> [Recommendation] {
        // 實現建議生成邏輯...
        return [
            Recommendation(id: UUID(), title: "保持一致的睡眠時間", description: "嘗試讓寶寶每天在相同的時間入睡和起床，有助於建立健康的睡眠習慣。", priority: .high),
            Recommendation(id: UUID(), title: "優化睡眠環境", description: "保持寶寶睡眠環境安靜、黑暗且溫度適宜，有助於提高睡眠質量。", priority: .medium)
        ]
    }
}

// MARK: - 視圖模型修復

/// 睡眠分析視圖模型 - 修復後的實現
class SleepAnalysisViewModel: ObservableObject {
    @Published var analysisResult: SleepPatternAnalysisResult?
    @Published var isAnalyzing = false
    @Published var error: AppError?
    @Published var analysisProgress: AnalysisProgress?
    @Published var availableAnalysisTypes: [AnalysisType] = []
    
    private let aiAnalysisService: AIAnalysisService
    private let networkMonitor: NetworkMonitor
    private let settingsService: SettingsService
    private var cancellables = Set<AnyCancellable>()
    
    init(aiAnalysisService: AIAnalysisService, networkMonitor: NetworkMonitor, settingsService: SettingsService) {
        self.aiAnalysisService = aiAnalysisService
        self.networkMonitor = networkMonitor
        self.settingsService = settingsService
        
        // 設置進度報告回調
        if let aiEngine = aiAnalysisService as? AIEngine {
            aiEngine.onProgressUpdate = { [weak self] progress in
                DispatchQueue.main.async {
                    self?.analysisProgress = progress
                }
            }
        }
        
        // 監聽網絡狀態變化
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.updateAvailableAnalysisTypes(isConnected: isConnected)
            }
            .store(in: &cancellables)
        
        // 初始化可用分析類型
        updateAvailableAnalysisTypes(isConnected: networkMonitor.isConnected)
    }
    
    func analyzeSleepPattern(for babyId: UUID) {
        isAnalyzing = true
        error = nil
        analysisProgress = nil
        
        let settings = settingsService.getAnalysisSettings()
        
        aiAnalysisService.analyzeSleepPattern(for: babyId, with: settings)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isAnalyzing = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] result in
                    self?.analysisResult = result
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateAvailableAnalysisTypes(isConnected: Bool) {
        if isConnected {
            // 在線模式：所有分析類型可用
            availableAnalysisTypes = [.basic, .standard, .comprehensive]
        } else {
            // 離線模式：僅基本分析可用
            availableAnalysisTypes = [.basic]
        }
    }
}

// MARK: - 依賴注入配置

/// 依賴注入容器
class DependencyContainer {
    static let shared = DependencyContainer()
    
    // 存儲服務
    lazy var settingsService: SettingsService = {
        return SettingsService()
    }()
    
    // 網絡監控
    lazy var networkMonitor: NetworkMonitor = {
        return NetworkMonitor()
    }()
    
    // 存儲庫
    lazy var sleepRepository: SleepRepository = {
        return SleepRepositoryImpl()
    }()
    
    lazy var routineRepository: RoutineRepository = {
        return RoutineRepositoryImpl()
    }()
    
    // 用例
    lazy var sleepUseCase: SleepUseCase = {
        return SleepUseCaseImpl(repository: sleepRepository)
    }()
    
    lazy var routineUseCase: RoutineUseCase = {
        return RoutineUseCaseImpl(repository: routineRepository)
    }()
    
    // API客戶端
    lazy var deepseekClient: DeepseekClientProtocol = {
        return DeepseekClientImpl()
    }()
    
    // AI引擎
    lazy var aiEngine: AIEngine = {
        return AIEngine(
            sleepUseCase: sleepUseCase,
            routineUseCase: routineUseCase,
            deepseekClient: deepseekClient,
            networkMonitor: networkMonitor,
            settingsService: settingsService
        )
    }()
    
    // 視圖模型
    func makeSleepAnalysisViewModel() -> SleepAnalysisViewModel {
        return SleepAnalysisViewModel(
            aiAnalysisService: aiEngine,
            networkMonitor: networkMonitor,
            settingsService: settingsService
        )
    }
}

// MARK: - 輔助類型

/// 分析類型
enum AnalysisType: String, CaseIterable {
    case basic = "basic"
    case standard = "standard"
    case comprehensive = "comprehensive"
    
    var displayName: String {
        switch self {
        case .basic: return "基本分析"
        case .standard: return "標準分析"
        case .comprehensive: return "全面分析"
        }
    }
}

/// 分析來源
enum AnalysisSource: String, Codable {
    case local = "local"
    case cloud = "cloud"
    case hybrid = "hybrid"
    
    var displayName: String {
        switch self {
        case .local: return "本地分析"
        case .cloud: return "雲端分析"
        case .hybrid: ret
(Content truncated due to size limit. Use line ranges to read in chunks)