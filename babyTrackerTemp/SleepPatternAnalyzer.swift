import Foundation

/// 睡眠模式分析器
class SleepPatternAnalyzer {
    // MARK: - 依賴
    private let sleepRepository: SleepRecordRepositoryProtocol
    
    // MARK: - 初始化
    
    init(sleepRepository: SleepRecordRepositoryProtocol) {
        self.sleepRepository = sleepRepository
    }
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeSleepPattern(babyId: String, dateRange: ClosedRange<Date>) async -> Result<SleepPatternResult, AnalysisError> {
        // 獲取睡眠記錄
        let recordsResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
        
        switch recordsResult {
        case .success(let records):
            // 檢查數據是否足夠
            guard !records.isEmpty else {
                return .failure(.insufficientData)
            }
            
            // 執行本地分析
            return .success(analyzeLocally(records: records))
            
        case .failure(let error):
            return .failure(.repositoryError(error))
        }
    }
    
    // MARK: - 私有方法
    
    /// 本地分析睡眠模式
    /// - Parameter records: 睡眠記錄
    /// - Returns: 分析結果
    private func analyzeLocally(records: [SleepRecord]) -> SleepPatternResult {
        // 計算平均睡眠時間
        let averageDuration = calculateAverageSleepDuration(records)
        
        // 識別睡眠模式
        let patterns = identifySleepPatterns(records)
        
        // 生成建議
        let recommendations = generateRecommendations(records, patterns)
        
        // 計算睡眠質量分數
        let qualityScore = calculateQualityScore(records, patterns)
        
        return SleepPatternResult(
            id: UUID().uuidString,
            analysisTime: Date(),
            patterns: patterns,
            recommendations: recommendations,
            qualityScore: qualityScore
        )
    }
    
    /// 計算平均睡眠時間
    /// - Parameter records: 睡眠記錄
    /// - Returns: 平均睡眠時間（小時）
    private func calculateAverageSleepDuration(_ records: [SleepRecord]) -> Double {
        let totalDuration = records.reduce(0.0) { $0 + $1.durationHours }
        return totalDuration / Double(records.count)
    }
    
    /// 識別睡眠模式
    /// - Parameter records: 睡眠記錄
    /// - Returns: 識別出的模式
    private func identifySleepPatterns(_ records: [SleepRecord]) -> [SleepPatternResult.Pattern] {
        var patterns: [SleepPatternResult.Pattern] = []
        
        // 檢查夜間睡眠模式
        let nightSleepRecords = records.filter { $0.isNightSleep }
        if !nightSleepRecords.isEmpty {
            let nightSleepDuration = nightSleepRecords.reduce(0.0) { $0 + $1.durationHours } / Double(nightSleepRecords.count)
            
            if nightSleepDuration < 8.0 {
                patterns.append(SleepPatternResult.Pattern(
                    type: "short_night_sleep",
                    confidence: 0.8,
                    description: "夜間睡眠時間較短，平均僅為\(String(format: "%.1f", nightSleepDuration))小時"
                ))
            } else if nightSleepDuration > 12.0 {
                patterns.append(SleepPatternResult.Pattern(
                    type: "long_night_sleep",
                    confidence: 0.8,
                    description: "夜間睡眠時間較長，平均為\(String(format: "%.1f", nightSleepDuration))小時"
                ))
            } else {
                patterns.append(SleepPatternResult.Pattern(
                    type: "normal_night_sleep",
                    confidence: 0.9,
                    description: "夜間睡眠時間正常，平均為\(String(format: "%.1f", nightSleepDuration))小時"
                ))
            }
        }
        
        // 檢查睡眠中斷模式
        let recordsWithInterruptions = records.filter { !$0.interruptions.isEmpty }
        if !recordsWithInterruptions.isEmpty {
            let averageInterruptions = recordsWithInterruptions.reduce(0) { $0 + $1.interruptions.count } / recordsWithInterruptions.count
            
            if averageInterruptions > 3 {
                patterns.append(SleepPatternResult.Pattern(
                    type: "frequent_interruptions",
                    confidence: 0.7,
                    description: "睡眠經常被中斷，平均每次睡眠中斷\(averageInterruptions)次"
                ))
            }
        }
        
        // 檢查睡眠規律性
        let sleepStartTimes = records.map { $0.startTime }
        let calendar = Calendar.current
        let hourComponents = sleepStartTimes.map { calendar.component(.hour, from: $0) }
        let hourVariance = calculateVariance(hourComponents)
        
        if hourVariance < 2.0 {
            patterns.append(SleepPatternResult.Pattern(
                type: "regular_sleep_schedule",
                confidence: 0.85,
                description: "睡眠時間規律，入睡時間變化小"
            ))
        } else if hourVariance > 4.0 {
            patterns.append(SleepPatternResult.Pattern(
                type: "irregular_sleep_schedule",
                confidence: 0.75,
                description: "睡眠時間不規律，入睡時間變化大"
            ))
        }
        
        return patterns
    }
    
    /// 生成建議
    /// - Parameters:
    ///   - records: 睡眠記錄
    ///   - patterns: 識別出的模式
    /// - Returns: 建議列表
    private func generateRecommendations(_ records: [SleepRecord], _ patterns: [SleepPatternResult.Pattern]) -> [SleepPatternResult.Recommendation] {
        var recommendations: [SleepPatternResult.Recommendation] = []
        
        // 根據模式生成建議
        for pattern in patterns {
            switch pattern.type {
            case "short_night_sleep":
                recommendations.append(SleepPatternResult.Recommendation(
                    category: "sleep_duration",
                    suggestion: "嘗試提前寶寶的就寢時間，確保充足的夜間睡眠",
                    priority: 1
                ))
                
            case "irregular_sleep_schedule":
                recommendations.append(SleepPatternResult.Recommendation(
                    category: "sleep_schedule",
                    suggestion: "建立規律的睡眠時間表，每天在相似的時間讓寶寶入睡",
                    priority: 1
                ))
                
            case "frequent_interruptions":
                recommendations.append(SleepPatternResult.Recommendation(
                    category: "sleep_quality",
                    suggestion: "檢查睡眠環境，減少可能導致寶寶醒來的噪音和光線",
                    priority: 2
                ))
                
            default:
                break
            }
        }
        
        // 添加通用建議
        if recommendations.isEmpty {
            recommendations.append(SleepPatternResult.Recommendation(
                category: "general",
                suggestion: "繼續保持當前的睡眠習慣，寶寶的睡眠模式良好",
                priority: 3
            ))
        }
        
        return recommendations
    }
    
    /// 計算睡眠質量分數
    /// - Parameters:
    ///   - records: 睡眠記錄
    ///   - patterns: 識別出的模式
    /// - Returns: 質量分數（0-100）
    private func calculateQualityScore(_ records: [SleepRecord], _ patterns: [SleepPatternResult.Pattern]) -> Int {
        var score = 70 // 基礎分數
        
        // 根據模式調整分數
        for pattern in patterns {
            switch pattern.type {
            case "normal_night_sleep":
                score += 10
            case "short_night_sleep":
                score -= 10
            case "regular_sleep_schedule":
                score += 10
            case "irregular_sleep_schedule":
                score -= 10
            case "frequent_interruptions":
                score -= 15
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
}
