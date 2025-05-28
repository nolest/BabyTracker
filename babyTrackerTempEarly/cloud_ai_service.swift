// CloudAIService.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：Deepseek API整合
// 雲端AI服務

import Foundation

/// 負責協調雲端AI分析服務，處理用戶設置、網絡狀態、數據匿名化和API調用
class CloudAIService {
    // MARK: - 單例模式
    static let shared = CloudAIService()
    
    // MARK: - 依賴
    private let networkMonitor = NetworkMonitor.shared
    private let userSettings = UserSettings.shared
    private let dataAnonymizer = DataAnonymizer.shared
    private let apiClient = DeepseekAPIClient.shared
    
    // MARK: - 緩存
    private var sleepAnalysisCache: [String: DeepseekSleepAnalysisResponse] = [:]
    private var routineAnalysisCache: [String: DeepseekRoutineAnalysisResponse] = [:]
    private var predictionCache: [String: DeepseekPredictionResponse] = [:]
    
    // MARK: - 常量
    private let cacheExpirationInterval: TimeInterval = 3600 // 1小時
    
    // MARK: - 初始化
    private init() {}
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式（雲端）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeSleepPatternCloud(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) async -> Result<SleepPatternResult, Error> {
        // 檢查是否可以使用雲端分析
        guard networkMonitor.canUseCloudAnalysis() else {
            return .failure(CloudError.cloudAnalysisDisabled)
        }
        
        do {
            // 獲取睡眠記錄
            let sleepRepository = SleepRecordRepository.shared
            let sleepRecordsResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
            
            switch sleepRecordsResult {
            case .success(let sleepRecords):
                // 檢查記錄數量
                guard !sleepRecords.isEmpty else {
                    return .failure(CloudError.insufficientData)
                }
                
                // 檢查緩存
                let cacheKey = generateCacheKey(babyId: babyId, dateRange: dateRange, type: "sleep")
                if let cachedResult = sleepAnalysisCache[cacheKey],
                   isCacheValid(cacheKey: cacheKey) {
                    return .success(convertToSleepPatternResult(cachedResult))
                }
                
                // 匿名化數據
                let anonymizedData = dataAnonymizer.anonymizeSleepRecords(sleepRecords)
                
                // 調用API
                let apiResult = await apiClient.analyzeSleep(data: anonymizedData)
                
                switch apiResult {
                case .success(let response):
                    // 更新緩存
                    sleepAnalysisCache[cacheKey] = response
                    
                    // 轉換為本地模型
                    let result = convertToSleepPatternResult(response)
                    return .success(result)
                    
                case .failure(let apiError):
                    return .failure(convertAPIError(apiError))
                }
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    
    /// 分析作息模式（雲端）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeRoutineCloud(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) async -> Result<RoutineAnalysisResult, Error> {
        // 檢查是否可以使用雲端分析
        guard networkMonitor.canUseCloudAnalysis() else {
            return .failure(CloudError.cloudAnalysisDisabled)
        }
        
        do {
            // 獲取活動記錄
            let activityRepository = ActivityRepository.shared
            let activitiesResult = await activityRepository.getActivities(babyId: babyId, dateRange: dateRange)
            
            switch activitiesResult {
            case .success(let activities):
                // 檢查記錄數量
                guard !activities.isEmpty else {
                    return .failure(CloudError.insufficientData)
                }
                
                // 檢查緩存
                let cacheKey = generateCacheKey(babyId: babyId, dateRange: dateRange, type: "routine")
                if let cachedResult = routineAnalysisCache[cacheKey],
                   isCacheValid(cacheKey: cacheKey) {
                    return .success(convertToRoutineAnalysisResult(cachedResult))
                }
                
                // 匿名化數據
                let anonymizedData = dataAnonymizer.anonymizeRoutineRecords(activities)
                
                // 調用API
                let apiResult = await apiClient.analyzeRoutine(data: anonymizedData)
                
                switch apiResult {
                case .success(let response):
                    // 更新緩存
                    routineAnalysisCache[cacheKey] = response
                    
                    // 轉換為本地模型
                    let result = convertToRoutineAnalysisResult(response)
                    return .success(result)
                    
                case .failure(let apiError):
                    return .failure(convertAPIError(apiError))
                }
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    
    /// 預測下次睡眠（雲端）
    /// - Parameter babyId: 寶寶ID
    /// - Returns: 預測結果或錯誤
    func predictNextSleepCloud(babyId: String) async -> Result<PredictionResult, Error> {
        // 檢查是否可以使用雲端分析
        guard networkMonitor.canUseCloudAnalysis() else {
            return .failure(CloudError.cloudAnalysisDisabled)
        }
        
        do {
            // 獲取分析時間範圍（過去14天）
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
            let dateRange = startDate...endDate
            
            // 檢查緩存
            let cacheKey = generateCacheKey(babyId: babyId, dateRange: dateRange, type: "prediction")
            if let cachedResult = predictionCache[cacheKey],
               isCacheValid(cacheKey: cacheKey, maxAge: 1800) { // 30分鐘
                return .success(convertToPredictionResult(cachedResult, babyId: babyId))
            }
            
            // 獲取睡眠記錄
            let sleepRepository = SleepRecordRepository.shared
            let sleepRecordsResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
            
            // 獲取活動記錄
            let activityRepository = ActivityRepository.shared
            let activitiesResult = await activityRepository.getActivities(babyId: babyId, dateRange: dateRange)
            
            // 檢查數據可用性
            guard case .success(let sleepRecords) = sleepRecordsResult,
                  case .success(let activities) = activitiesResult,
                  !sleepRecords.isEmpty,
                  !activities.isEmpty else {
                return .failure(CloudError.insufficientData)
            }
            
            // 匿名化數據
            let anonymizedSleepData = dataAnonymizer.anonymizeSleepRecords(sleepRecords)
            let anonymizedRoutineData = dataAnonymizer.anonymizeRoutineRecords(activities)
            
            // 調用API
            let apiResult = await apiClient.generatePrediction(
                sleepData: anonymizedSleepData,
                routineData: anonymizedRoutineData
            )
            
            switch apiResult {
            case .success(let response):
                // 更新緩存
                predictionCache[cacheKey] = response
                
                // 轉換為本地模型
                let result = convertToPredictionResult(response, babyId: babyId)
                return .success(result)
                
            case .failure(let apiError):
                return .failure(convertAPIError(apiError))
            }
        } catch {
            return .failure(error)
        }
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
        
        // 轉換下次餵食預測
        let nextFeedingPrediction: NextFeedingPrediction?
        if let nextFeeding = response.nextFeeding {
            let now = Date()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            
            // 計算預測時間
            let earliestStartTime = calen
(Content truncated due to size limit. Use line ranges to read in chunks)