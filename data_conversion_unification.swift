// data_conversion_unification.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 數據轉換統一實現

import Foundation

// MARK: - 數據轉換協議

/// 數據轉換協議，定義數據轉換的標準接口
protocol DataConverter<Source, Target> {
    associatedtype Source
    associatedtype Target
    
    /// 將源數據轉換為目標數據
    /// - Parameter source: 源數據
    /// - Returns: 目標數據
    func convert(_ source: Source) -> Target
}

// MARK: - 睡眠分析數據轉換器

/// 睡眠分析數據轉換器，將Deepseek睡眠分析響應轉換為本地睡眠模式結果
struct SleepAnalysisConverter: DataConverter {
    typealias Source = DeepseekSleepAnalysisResponse
    typealias Target = SleepPatternResult
    
    /// 將Deepseek睡眠分析響應轉換為本地睡眠模式結果
    /// - Parameter response: Deepseek響應
    /// - Returns: 本地睡眠模式結果
    func convert(_ response: DeepseekSleepAnalysisResponse) -> SleepPatternResult {
        // 轉換睡眠模式類型
        let patternType = convertSleepPatternType(response.sleepPatternType)
        
        // 轉換環境因素影響
        let environmentFactors = SleepEnvironmentFactors(
            lightImpact: convertFactorImpact(response.environmentalFactorImpact.light),
            noiseImpact: convertFactorImpact(response.environmentalFactorImpact.noise),
            temperatureImpact: convertFactorImpact(response.environmentalFactorImpact.temperature),
            humidityImpact: convertFactorImpact(response.environmentalFactorImpact.humidity)
        )
        
        // 轉換睡眠趨勢
        let trend = convertSleepTrend(response.sleepTrend)
        
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
    
    /// 轉換睡眠模式類型
    /// - Parameter typeString: 睡眠模式類型字符串
    /// - Returns: 睡眠模式類型枚舉
    private func convertSleepPatternType(_ typeString: String) -> SleepPatternType {
        switch typeString.lowercased() {
        case "highly_regular":
            return .highlyRegular
        case "moderately_regular":
            return .moderatelyRegular
        case "irregular":
            return .irregular
        case "evolving":
            return .evolving
        case "transitioning":
            return .transitioning
        default:
            return .insufficient
        }
    }
    
    /// 轉換因素影響
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
    
    /// 轉換睡眠趨勢
    /// - Parameter trendString: 睡眠趨勢字符串
    /// - Returns: 睡眠趨勢枚舉
    private func convertSleepTrend(_ trendString: String) -> SleepTrend {
        switch trendString.lowercased() {
        case "improving":
            return .improving
        case "stable":
            return .stable
        case "declining":
            return .declining
        case "fluctuating":
            return .fluctuating
        default:
            return .insufficient
        }
    }
}

// MARK: - 作息分析數據轉換器

/// 作息分析數據轉換器，將Deepseek作息分析響應轉換為本地作息分析結果
struct RoutineAnalysisConverter: DataConverter {
    typealias Source = DeepseekRoutineAnalysisResponse
    typealias Target = RoutineAnalysisResult
    
    /// 將Deepseek作息分析響應轉換為本地作息分析結果
    /// - Parameter response: Deepseek響應
    /// - Returns: 本地作息分析結果
    func convert(_ response: DeepseekRoutineAnalysisResponse) -> RoutineAnalysisResult {
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
        let trend = convertRoutineTrend(response.routineTrend)
        
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
    
    /// 轉換作息趨勢
    /// - Parameter trendString: 作息趨勢字符串
    /// - Returns: 作息趨勢枚舉
    private func convertRoutineTrend(_ trendString: String) -> RoutineTrend {
        switch trendString.lowercased() {
        case "improving":
            return .improving
        case "stable":
            return .stable
        case "declining":
            return .declining
        case "fluctuating":
            return .fluctuating
        default:
            return .insufficient
        }
    }
}

// MARK: - 預測數據轉換器

/// 預測數據轉換器，將Deepseek預測響應轉換為本地預測結果
struct PredictionConverter: DataConverter {
    typealias Source = (DeepseekPredictionResponse, String)
    typealias Target = PredictionResult
    
    /// 將Deepseek預測響應轉換為本地預測結果
    /// - Parameter source: Deepseek響應和寶寶ID的元組
    /// - Returns: 本地預測結果
    func convert(_ source: (DeepseekPredictionResponse, String)) -> PredictionResult {
        let (response, babyId) = source
        
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

// MARK: - 數據轉換工廠

/// 數據轉換工廠，提供各種數據轉換器的實例
class DataConverterFactory {
    /// 獲取睡眠分析數據轉換器
    /// - Returns: 睡眠分析數據轉換器
    static func getSleepAnalysisConverter() -> SleepAnalysisConverter {
        return SleepAnalysisConverter()
    }
    
    /// 獲取作息分析數據轉換器
    /// - Returns: 作息分析數據轉換器
    static func getRoutineAnalysisConverter() -> RoutineAnalysisConverter {
        return RoutineAnalysisConverter()
    }
    
    /// 獲取預測數據轉換器
    /// - Returns: 預測數據轉換器
    static func getPredictionConverter() -> PredictionConverter {
        return PredictionConverter()
    }
}

// MARK: - 修正後的CloudAIService

extension CloudAIService {
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
                        // 使用轉換器轉換緩存結果
                        let converter = DataConverterFactory.getSleepAnalysisConverter()
                        let result = converter.convert(cachedResult)
                        promise(.success(result))
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
                        
                        // 使用轉換器轉換API結果
                        let converter = DataConverterFactory.getSleepAnalysisConverter()
                        let result = converter.convert(response)
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
                        // 使用轉換器轉換緩存結果
                        let converter = DataConverterFactory.getRoutineAnalysisConverter()
                        let result = converter.convert(cachedResult)
                        promise(.success(result))
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
                        
                        // 使用轉換器轉換API結果
                        let converter = DataConverterFactory.getRoutineAnalysisConverter()
                        let result = converter.convert(response)
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
                    // 使用轉換器轉換緩存結果
                    let converter = DataConverterFactory.getPredictionConverter()
                    let result = converter.convert((cachedResult, babyId))
                    promise(.success(result))
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
                    
                    // 使用轉換器轉換API結果
                    let converter = DataConverterFactory.getPredictionConverter()
                    let result = converter.convert((response, babyId))
                    promise(.success(result))
                    
                case .failure(let apiError):
                    promise(.failure(self.convertAPIError(apiError)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
