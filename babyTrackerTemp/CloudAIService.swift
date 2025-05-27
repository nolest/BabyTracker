import Foundation

/// 雲端AI服務
class CloudAIService {
    // MARK: - 單例模式
    static let shared = CloudAIService()
    
    private init() {}
    
    // MARK: - 依賴
    private let networkMonitor = NetworkMonitor.shared
    private let userSettings = UserSettings.shared
    private let dataAnonymizer = DataAnonymizer.shared
    private let apiClient = DeepseekAPIClient.shared
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式（雲端）
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    /// - Returns: 分析結果或錯誤
    func analyzeSleepPattern(sleepRecords: [SleepRecord]) async -> Result<SleepPatternResult, CloudError> {
        // 檢查是否可以使用雲端分析
        guard canUseCloudAnalysis() else {
            return .failure(.cloudAnalysisDisabled)
        }
        
        // 檢查數據是否足夠
        guard !sleepRecords.isEmpty else {
            return .failure(.insufficientData)
        }
        
        // 匿名化數據
        let anonymizedData = dataAnonymizer.anonymizeSleepRecords(sleepRecords)
        
        // 發送到API
        let apiResult = await apiClient.analyzeSleep(data: anonymizedData)
        
        // 處理結果
        switch apiResult {
        case .success(let response):
            return .success(convertToSleepPatternResult(response))
        case .failure(let error):
            return .failure(convertToCloudError(error))
        }
    }
    
    /// 分析作息規律（雲端）
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    /// - Returns: 分析結果或錯誤
    func analyzeRoutine(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity]
    ) async -> Result<RoutineAnalysisResult, CloudError> {
        // 檢查是否可以使用雲端分析
        guard canUseCloudAnalysis() else {
            return .failure(.cloudAnalysisDisabled)
        }
        
        // 檢查數據是否足夠
        guard !sleepRecords.isEmpty || !feedingRecords.isEmpty || !activities.isEmpty else {
            return .failure(.insufficientData)
        }
        
        // 匿名化數據
        let anonymizedData = dataAnonymizer.anonymizeRoutineRecords(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities
        )
        
        // 發送到API
        let apiResult = await apiClient.analyzeRoutine(data: anonymizedData)
        
        // 處理結果
        switch apiResult {
        case .success(let response):
            return .success(convertToRoutineAnalysisResult(response))
        case .failure(let error):
            return .failure(convertToCloudError(error))
        }
    }
    
    /// 預測下一次睡眠（雲端）
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    /// - Returns: 預測結果或錯誤
    func predictNextSleep(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity]
    ) async -> Result<PredictionResult, CloudError> {
        // 檢查是否可以使用雲端分析
        guard canUseCloudAnalysis() else {
            return .failure(.cloudAnalysisDisabled)
        }
        
        // 檢查數據是否足夠
        guard !sleepRecords.isEmpty else {
            return .failure(.insufficientData)
        }
        
        // 匿名化數據
        let anonymizedSleepData = dataAnonymizer.anonymizeSleepRecords(sleepRecords)
        let anonymizedRoutineData = dataAnonymizer.anonymizeRoutineRecords(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities
        )
        
        // 發送到API
        let apiResult = await apiClient.generatePrediction(
            sleepData: anonymizedSleepData,
            routineData: anonymizedRoutineData
        )
        
        // 處理結果
        switch apiResult {
        case .success(let response):
            return .success(convertToPredictionResult(response))
        case .failure(let error):
            return .failure(convertToCloudError(error))
        }
    }
    
    // MARK: - 私有方法
    
    /// 檢查是否可以使用雲端分析
    private func canUseCloudAnalysis() -> Bool {
        return networkMonitor.canUseCloudAnalysis()
    }
    
    /// 將API錯誤轉換為雲端錯誤
    private func convertToCloudError(_ error: DeepseekAPIClient.APIError) -> CloudError {
        switch error {
        case .invalidAPIKey:
            return .invalidAPIKey
        case .networkError:
            return .networkError
        case .serverError:
            return .serverError
        case .rateLimitExceeded:
            return .rateLimitExceeded
        case .timeout:
            return .timeout
        default:
            return .unknownError
        }
    }
    
    /// 將API響應轉換為睡眠模式分析結果
    private func convertToSleepPatternResult(_ response: DeepseekSleepAnalysisResponse) -> SleepPatternResult {
        let patterns = response.sleepPatterns.map { pattern in
            return SleepPatternResult.Pattern(
                type: pattern.type,
                confidence: pattern.confidence,
                description: pattern.description
            )
        }
        
        let recommendations = response.recommendations.map { recommendation in
            return SleepPatternResult.Recommendation(
                category: recommendation.category,
                suggestion: recommendation.suggestion,
                priority: recommendation.priority
            )
        }
        
        return SleepPatternResult(
            id: response.id,
            analysisTime: response.analysisTime,
            patterns: patterns,
            recommendations: recommendations,
            qualityScore: response.qualityScore
        )
    }
    
    /// 將API響應轉換為作息分析結果
    private func convertToRoutineAnalysisResult(_ response: DeepseekRoutineAnalysisResponse) -> RoutineAnalysisResult {
        let patterns = response.routinePatterns.map { pattern in
            return RoutineAnalysisResult.Pattern(
                type: pattern.type,
                confidence: pattern.confidence,
                description: pattern.description
            )
        }
        
        let recommendations = response.recommendations.map { recommendation in
            return RoutineAnalysisResult.Recommendation(
                category: recommendation.category,
                suggestion: recommendation.suggestion,
                priority: recommendation.priority
            )
        }
        
        return RoutineAnalysisResult(
            id: response.id,
            analysisTime: response.analysisTime,
            patterns: patterns,
            recommendations: recommendations,
            regularityScore: response.regularityScore
        )
    }
    
    /// 將API響應轉換為預測結果
    private func convertToPredictionResult(_ response: DeepseekPredictionResponse) -> PredictionResult {
        let sleepPredictions = response.sleepPredictions.map { prediction in
            return PredictionResult.SleepPrediction(
                predictedStartTime: prediction.predictedStartTime,
                predictedDuration: prediction.predictedDuration,
                confidence: prediction.confidence
            )
        }
        
        let feedingPredictions = response.feedingPredictions.map { prediction in
            return PredictionResult.FeedingPrediction(
                predictedTime: prediction.predictedTime,
                predictedType: prediction.predictedType,
                confidence: prediction.confidence
            )
        }
        
        return PredictionResult(
            id: response.id,
            predictionTime: response.predictionTime,
            sleepPredictions: sleepPredictions,
            feedingPredictions: feedingPredictions,
            confidenceScore: response.confidenceScore
        )
    }
}

// MARK: - 結果模型

/// 睡眠模式分析結果
struct SleepPatternResult {
    let id: String
    let analysisTime: Date
    let patterns: [Pattern]
    let recommendations: [Recommendation]
    let qualityScore: Int
    
    struct Pattern {
        let type: String
        let confidence: Double
        let description: String
    }
    
    struct Recommendation {
        let category: String
        let suggestion: String
        let priority: Int
    }
}

/// 作息分析結果
struct RoutineAnalysisResult {
    let id: String
    let analysisTime: Date
    let patterns: [Pattern]
    let recommendations: [Recommendation]
    let regularityScore: Int
    
    struct Pattern {
        let type: String
        let confidence: Double
        let description: String
    }
    
    struct Recommendation {
        let category: String
        let suggestion: String
        let priority: Int
    }
}

/// 預測結果
struct PredictionResult {
    let id: String
    let predictionTime: Date
    let sleepPredictions: [SleepPrediction]
    let feedingPredictions: [FeedingPrediction]
    let confidenceScore: Int
    
    struct SleepPrediction {
        let predictedStartTime: Date
        let predictedDuration: TimeInterval
        let confidence: Double
    }
    
    struct FeedingPrediction {
        let predictedTime: Date
        let predictedType: String
        let confidence: Double
    }
}
