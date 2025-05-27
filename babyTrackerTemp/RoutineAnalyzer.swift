import Foundation

/// 作息模式分析器
class RoutineAnalyzer {
    // MARK: - 依賴
    private let activityRepository: ActivityRepositoryProtocol
    private let sleepRepository: SleepRecordRepositoryProtocol
    private let feedingRepository: FeedingRepositoryProtocol
    
    // MARK: - 初始化
    
    init(activityRepository: ActivityRepositoryProtocol,
         sleepRepository: SleepRecordRepositoryProtocol,
         feedingRepository: FeedingRepositoryProtocol) {
        self.activityRepository = activityRepository
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
    }
    
    // MARK: - 公開方法
    
    /// 分析作息規律
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeRoutine(babyId: String, dateRange: ClosedRange<Date>) async -> Result<RoutineAnalysisResult, AnalysisError> {
        // 獲取睡眠記錄
        let sleepResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
        
        // 獲取餵食記錄
        let feedingResult = await feedingRepository.getFeedingRecords(babyId: babyId, dateRange: dateRange)
        
        // 獲取活動記錄
        let activityResult = await activityRepository.getActivities(babyId: babyId, dateRange: dateRange)
        
        // 檢查是否有任何錯誤
        if case .failure(let error) = sleepResult {
            return .failure(.repositoryError(error))
        }
        
        if case .failure(let error) = feedingResult {
            return .failure(.repositoryError(error))
        }
        
        if case .failure(let error) = activityResult {
            return .failure(.repositoryError(error))
        }
        
        // 提取記錄
        guard case .success(let sleepRecords) = sleepResult,
              case .success(let feedingRecords) = feedingResult,
              case .success(let activities) = activityResult else {
            return .failure(.processingError)
        }
        
        // 檢查數據是否足夠
        if sleepRecords.isEmpty && feedingRecords.isEmpty && activities.isEmpty {
            return .failure(.insufficientData)
        }
        
        // 執行本地分析
        return .success(analyzeLocally(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities
        ))
    }
    
    // MARK: - 私有方法
    
    /// 本地分析作息規律
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    /// - Returns: 分析結果
    private func analyzeLocally(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity]
    ) -> RoutineAnalysisResult {
        // 識別作息模式
        let patterns = identifyRoutinePatterns(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities
        )
        
        // 生成建議
        let recommendations = generateRecommendations(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities,
            patterns: patterns
        )
        
        // 計算規律性分數
        let regularityScore = calculateRegularityScore(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities,
            patterns: patterns
        )
        
        return RoutineAnalysisResult(
            id: UUID().uuidString,
            analysisTime: Date(),
            patterns: patterns,
            recommendations: recommendations,
            regularityScore: regularityScore
        )
    }
    
    /// 識別作息模式
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    /// - Returns: 識別出的模式
    private func identifyRoutinePatterns(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity]
    ) -> [RoutineAnalysisResult.Pattern] {
        var patterns: [RoutineAnalysisResult.Pattern] = []
        
        // 分析睡眠規律性
        if !sleepRecords.isEmpty {
            let sleepStartTimes = sleepRecords.map { $0.startTime }
            let calendar = Calendar.current
            let hourComponents = sleepStartTimes.map { calendar.component(.hour, from: $0) }
            let hourVariance = calculateVariance(hourComponents)
            
            if hourVariance < 2.0 {
                patterns.append(RoutineAnalysisResult.Pattern(
                    type: "regular_sleep_schedule",
                    confidence: 0.85,
                    description: "睡眠時間規律，入睡時間變化小"
                ))
            } else if hourVariance > 4.0 {
                patterns.append(RoutineAnalysisResult.Pattern(
                    type: "irregular_sleep_schedule",
                    confidence: 0.75,
                    description: "睡眠時間不規律，入睡時間變化大"
                ))
            }
        }
        
        // 分析餵食規律性
        if !feedingRecords.isEmpty {
            let feedingTimes = feedingRecords.map { $0.startTime }
            let calendar = Calendar.current
            let hourComponents = feedingTimes.map { calendar.component(.hour, from: $0) }
            let hourVariance = calculateVariance(hourComponents)
            
            if hourVariance < 1.5 {
                patterns.append(RoutineAnalysisResult.Pattern(
                    type: "regular_feeding_schedule",
                    confidence: 0.8,
                    description: "餵食時間規律，餵食時間變化小"
                ))
            } else if hourVariance > 3.0 {
                patterns.append(RoutineAnalysisResult.Pattern(
                    type: "irregular_feeding_schedule",
                    confidence: 0.7,
                    description: "餵食時間不規律，餵食時間變化大"
                ))
            }
            
            // 分析餵食類型分佈
            let feedingTypes = feedingRecords.map { $0.type }
            let typeDistribution = calculateDistribution(feedingTypes)
            
            if let (dominantType, percentage) = findDominantType(typeDistribution), percentage > 0.7 {
                patterns.append(RoutineAnalysisResult.Pattern(
                    type: "dominant_feeding_type",
                    confidence: 0.9,
                    description: "主要餵食類型為\(dominantType.localizedName)，佔比\(Int(percentage * 100))%"
                ))
            }
        }
        
        // 分析活動規律性
        if !activities.isEmpty {
            let activityTypes = activities.map { $0.type }
            let typeDistribution = calculateDistribution(activityTypes)
            
            // 檢查是否有規律的活動模式
            if typeDistribution.count >= 3 {
                patterns.append(RoutineAnalysisResult.Pattern(
                    type: "diverse_activities",
                    confidence: 0.75,
                    description: "活動類型多樣，包含\(typeDistribution.count)種不同活動"
                ))
            }
        }
        
        // 如果沒有識別出任何模式，添加一個默認模式
        if patterns.isEmpty {
            patterns.append(RoutineAnalysisResult.Pattern(
                type: "insufficient_data_pattern",
                confidence: 0.5,
                description: "數據不足，無法識別明確的作息模式"
            ))
        }
        
        return patterns
    }
    
    /// 生成建議
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    ///   - patterns: 識別出的模式
    /// - Returns: 建議列表
    private func generateRecommendations(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity],
        patterns: [RoutineAnalysisResult.Pattern]
    ) -> [RoutineAnalysisResult.Recommendation] {
        var recommendations: [RoutineAnalysisResult.Recommendation] = []
        
        // 根據模式生成建議
        for pattern in patterns {
            switch pattern.type {
            case "irregular_sleep_schedule":
                recommendations.append(RoutineAnalysisResult.Recommendation(
                    category: "sleep_schedule",
                    suggestion: "建立規律的睡眠時間表，每天在相似的時間讓寶寶入睡",
                    priority: 1
                ))
                
            case "irregular_feeding_schedule":
                recommendations.append(RoutineAnalysisResult.Recommendation(
                    category: "feeding_schedule",
                    suggestion: "嘗試在固定的時間餵食，幫助寶寶建立規律的餵食習慣",
                    priority: 2
                ))
                
            case "insufficient_data_pattern":
                recommendations.append(RoutineAnalysisResult.Recommendation(
                    category: "data_collection",
                    suggestion: "繼續記錄寶寶的日常活動，以獲得更準確的作息分析",
                    priority: 3
                ))
                
            default:
                break
            }
        }
        
        // 添加通用建議
        if recommendations.isEmpty {
            recommendations.append(RoutineAnalysisResult.Recommendation(
                category: "general",
                suggestion: "繼續保持當前的作息習慣，寶寶的作息模式良好",
                priority: 3
            ))
        }
        
        return recommendations
    }
    
    /// 計算規律性分數
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    ///   - patterns: 識別出的模式
    /// - Returns: 規律性分數（0-100）
    private func calculateRegularityScore(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity],
        patterns: [RoutineAnalysisResult.Pattern]
    ) -> Int {
        var score = 70 // 基礎分數
        
        // 根據模式調整分數
        for pattern in patterns {
            switch pattern.type {
            case "regular_sleep_schedule":
                score += 10
            case "irregular_sleep_schedule":
                score -= 10
            case "regular_feeding_schedule":
                score += 10
            case "irregular_feeding_schedule":
                score -= 10
            case "diverse_activities":
                score += 5
            case "insufficient_data_pattern":
                score -= 5
            default:
                break
            }
        }
        
        // 確保分數在0-100範圍內
        return min(100, max(0, score))
    }
    
    /// 計算方差
    /// - Parameter values: 數值列表
    /// - Returns: 方差
    private func calculateVariance(_ values: [Int]) -> Double {
        let count = Double(values.count)
        guard count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Int(count)
        let variance = values.reduce(0.0) { $0 + pow(Double($1 - mean), 2) } / count
        
        return variance
    }
    
    /// 計算分佈
    /// - Parameter values: 值列表
    /// - Returns: 分佈字典
    private func calculateDistribution<T: Hashable>(_ values: [T]) -> [T: Int] {
        var distribution: [T: Int] = [:]
        
        for value in values {
            distribution[value, default: 0] += 1
        }
        
        return distribution
    }
    
    /// 查找主要類型
    /// - Parameter distribution: 分佈字典
    /// - Returns: 主要類型和百分比
    private func findDominantType<T>(_ distribution: [T: Int]) -> (T, Double)? {
        guard !distribution.isEmpty else { return nil }
        
        let total = distribution.values.reduce(0, +)
        guard total > 0 else { return nil }
        
        let sorted = distribution.sorted { $0.value > $1.value }
        let dominant = sorted.first!
        let percentage = Double(dominant.value) / Double(total)
        
        return (dominant.key, percentage)
    }
}
