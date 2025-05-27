// RoutineAnalyzer.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：本地AI分析功能
// 作息模式分析器實現

import Foundation
import CoreData
import Accelerate

// MARK: - 作息模式分析結果
struct RoutinePatternResult {
    // 基本統計數據
    let analyzedDateRange: ClosedRange<Date>
    let analyzedRecordsCount: Int
    let confidenceScore: Double // 分析可信度（0-1）
    let analysisTimestamp: Date
    
    // 作息規律性
    let regularityScore: Int // 規律性評分（0-100）
    let routinePatternType: RoutinePatternType
    
    // 典型作息循環
    let typicalCycles: [RoutineCycle]
    
    // 活動時間分佈
    let activityDistribution: ActivityDistribution
    
    // 作息趨勢
    let routineTrend: RoutineTrend
    
    // 建議的作息時間表
    let suggestedSchedule: [ScheduleItem]?
}

// 作息模式類型
enum RoutinePatternType: String, CaseIterable {
    case highlyRegular = "highlyRegular" // 高度規律
    case moderatelyRegular = "moderatelyRegular" // 中度規律
    case irregular = "irregular" // 不規律
    case evolving = "evolving" // 正在形成中
    case transitioning = "transitioning" // 正在轉變中
    case insufficient = "insufficient" // 數據不足
    
    var localizedName: String {
        switch self {
        case .highlyRegular:
            return NSLocalizedString("高度規律", comment: "Highly regular routine pattern")
        case .moderatelyRegular:
            return NSLocalizedString("中度規律", comment: "Moderately regular routine pattern")
        case .irregular:
            return NSLocalizedString("不規律", comment: "Irregular routine pattern")
        case .evolving:
            return NSLocalizedString("正在形成中", comment: "Evolving routine pattern")
        case .transitioning:
            return NSLocalizedString("正在轉變中", comment: "Transitioning routine pattern")
        case .insufficient:
            return NSLocalizedString("數據不足", comment: "Insufficient data for routine pattern")
        }
    }
    
    var description: String {
        switch self {
        case .highlyRegular:
            return NSLocalizedString("寶寶的作息時間非常規律，有助於建立健康的生理時鐘。", comment: "Highly regular routine pattern description")
        case .moderatelyRegular:
            return NSLocalizedString("寶寶的作息模式有一定規律性，但仍有些波動。", comment: "Moderately regular routine pattern description")
        case .irregular:
            return NSLocalizedString("寶寶的作息時間變化較大，可能需要更一致的日常習慣。", comment: "Irregular routine pattern description")
        case .evolving:
            return NSLocalizedString("寶寶的作息模式正在形成中，這在發育過程中很常見。", comment: "Evolving routine pattern description")
        case .transitioning:
            return NSLocalizedString("寶寶的作息模式正在轉變，可能是因為發育里程碑或環境變化。", comment: "Transitioning routine pattern description")
        case .insufficient:
            return NSLocalizedString("記錄的數據不足以確定作息模式，請繼續記錄。", comment: "Insufficient data for routine pattern description")
        }
    }
}

// 作息循環
struct RoutineCycle {
    let sequence: [ActivityType]
    let averageDuration: TimeInterval // 整個循環的平均持續時間
    let frequency: Double // 每天出現的平均次數
    let regularityScore: Int // 規律性評分（0-100）
    
    var localizedDescription: String {
        let activityNames = sequence.map { $0.localizedName }.joined(separator: " → ")
        let hours = averageDuration / 3600
        let minutes = (averageDuration.truncatingRemainder(dividingBy: 3600)) / 60
        
        return String(format: NSLocalizedString("%@（平均持續%.1f小時%.0f分鐘，每天%.1f次，規律性%d%%）", comment: "Routine cycle description"),
                      activityNames, floor(hours), floor(minutes), frequency, regularityScore)
    }
}

// 活動時間分佈
struct ActivityDistribution {
    let sleepPercentage: Double // 睡眠時間佔比
    let feedingPercentage: Double // 餵食時間佔比
    let playPercentage: Double // 玩耍時間佔比
    let otherPercentage: Double // 其他活動時間佔比
    
    // 各活動的平均持續時間（小時）
    let averageSleepDuration: Double
    let averageFeedingDuration: Double
    let averagePlayDuration: Double
    let averageOtherDuration: Double
    
    // 各活動的平均間隔時間（小時）
    let averageSleepInterval: Double
    let averageFeedingInterval: Double
}

// 作息趨勢
enum RoutineTrend: String, CaseIterable {
    case improving = "improving" // 改善中
    case stable = "stable" // 穩定
    case declining = "declining" // 下降中
    case fluctuating = "fluctuating" // 波動
    case insufficient = "insufficient" // 數據不足
    
    var localizedName: String {
        switch self {
        case .improving:
            return NSLocalizedString("改善中", comment: "Improving routine trend")
        case .stable:
            return NSLocalizedString("穩定", comment: "Stable routine trend")
        case .declining:
            return NSLocalizedString("下降中", comment: "Declining routine trend")
        case .fluctuating:
            return NSLocalizedString("波動", comment: "Fluctuating routine trend")
        case .insufficient:
            return NSLocalizedString("數據不足", comment: "Insufficient data for routine trend")
        }
    }
    
    var description: String {
        switch self {
        case .improving:
            return NSLocalizedString("寶寶的作息規律性正在改善。", comment: "Improving routine trend description")
        case .stable:
            return NSLocalizedString("寶寶的作息模式保持穩定。", comment: "Stable routine trend description")
        case .declining:
            return NSLocalizedString("寶寶的作息規律性有所下降，可能需要關注。", comment: "Declining routine trend description")
        case .fluctuating:
            return NSLocalizedString("寶寶的作息模式有較大波動，可能受到發育或環境因素影響。", comment: "Fluctuating routine trend description")
        case .insufficient:
            return NSLocalizedString("記錄的數據不足以確定作息趨勢，請繼續記錄。", comment: "Insufficient data for routine trend description")
        }
    }
}

// 建議的作息時間表項目
struct ScheduleItem {
    let activityType: ActivityType
    let suggestedStartTime: Date
    let suggestedDuration: TimeInterval
    let confidence: Double // 0-1
    
    var localizedDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startTimeString = formatter.string(from: suggestedStartTime)
        
        let hours = suggestedDuration / 3600
        let minutes = (suggestedDuration.truncatingRemainder(dividingBy: 3600)) / 60
        
        var durationString = ""
        if hours >= 1 {
            durationString += String(format: "%.0f小時", floor(hours))
        }
        if minutes > 0 {
            durationString += String(format: "%.0f分鐘", floor(minutes))
        }
        
        return String(format: NSLocalizedString("%@：%@（持續%@）", comment: "Schedule item description"),
                      activityType.localizedName, startTimeString, durationString)
    }
}

// MARK: - 作息模式分析器
class RoutineAnalyzer {
    // 依賴
    private let activityRepository: ActivityRepository
    private let sleepRepository: SleepRecordRepository
    private let feedingRepository: FeedingRepository
    
    // 常量
    private let minimumRecordsForAnalysis = 10 // 進行分析所需的最少記錄數
    private let minimumDaysForAnalysis = 3 // 進行分析所需的最少天數
    private let minimumRecordsForTrendAnalysis = 20 // 進行趨勢分析所需的最少記錄數
    private let minimumDaysForTrendAnalysis = 7 // 進行趨勢分析所需的最少天數
    
    // 初始化
    init(activityRepository: ActivityRepository, sleepRepository: SleepRecordRepository, feedingRepository: FeedingRepository) {
        self.activityRepository = activityRepository
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
    }
    
    // 分析指定寶寶在特定時間範圍內的作息模式
    func analyzeRoutinePattern(babyId: String, dateRange: ClosedRange<Date>) async -> Result<RoutinePatternResult, Error> {
        do {
            // 獲取活動記錄
            let activitiesResult = await activityRepository.getActivities(babyId: babyId, dateRange: dateRange)
            let sleepRecordsResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
            let feedingRecordsResult = await feedingRepository.getFeedingRecords(babyId: babyId, dateRange: dateRange)
            
            // 檢查是否有錯誤
            if case .failure(let error) = activitiesResult {
                return .failure(error)
            }
            if case .failure(let error) = sleepRecordsResult {
                return .failure(error)
            }
            if case .failure(let error) = feedingRecordsResult {
                return .failure(error)
            }
            
            // 獲取記錄
            guard case .success(let activities) = activitiesResult,
                  case .success(let sleepRecords) = sleepRecordsResult,
                  case .success(let feedingRecords) = feedingRecordsResult else {
                return .failure(NSError(domain: "RoutineAnalyzer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get records"]))
            }
            
            // 合併所有活動記錄
            var allActivities: [ActivityRecord] = []
            
            // 添加一般活動
            allActivities.append(contentsOf: activities.map { activity in
                return ActivityRecord(
                    id: activity.id,
                    type: activity.type,
                    startTime: activity.startTime,
                    endTime: activity.endTime ?? activity.startTime.addingTimeInterval(30 * 60), // 默認30分鐘
                    notes: activity.notes
                )
            })
            
            // 添加睡眠記錄
            allActivities.append(contentsOf: sleepRecords.map { sleep in
                return ActivityRecord(
                    id: sleep.id,
                    type: .sleep,
                    startTime: sleep.startTime,
                    endTime: sleep.endTime,
                    notes: sleep.notes
                )
            })
            
            // 添加餵食記錄
            allActivities.append(contentsOf: feedingRecords.map { feeding in
                return ActivityRecord(
                    id: feeding.id,
                    type: .feeding,
                    startTime: feeding.startTime,
                    endTime: feeding.endTime ?? feeding.startTime.addingTimeInterval(20 * 60), // 默認20分鐘
                    notes: feeding.notes
                )
            })
            
            // 檢查記錄數量是否足夠
            guard allActivities.count >= minimumRecordsForAnalysis else {
                return .success(createInsufficientDataResult(dateRange: dateRange, recordsCount: allActivities.count))
            }
            
            // 檢查天數是否足夠
            let calendar = Calendar.current
            let days = Set(allActivities.map { calendar.startOfDay(for: $0.startTime) }).count
            guard days >= minimumDaysForAnalysis else {
                return .success(createInsufficientDataResult(dateRange: dateRange, recordsCount: allActivities.count))
            }
            
            // 進行分析
            return .success(analyzeActivities(allActivities, dateRange: dateRange))
            
        } catch {
            return .failure(error)
        }
    }
    
    // 分析活動記錄
    private func analyzeActivities(_ activities: [ActivityRecord], dateRange: ClosedRange<Date>) -> RoutinePatternResult {
        // 按時間排序
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        
        // 計算作息規律性
        let regularityScore = calculateRegularityScore(sortedActivities)
        
        // 判定作息模式類型
        let routinePatternType = determineRoutinePatternType(
            activities: sortedActivities,
            regularityScore: regularityScore
        )
        
        // 識別典型作息循環
        let typicalCycles = identifyTypicalCycles(sortedActivities)
        
        // 計算活動時間分佈
        let activityDistribution = calculateActivityDistribution(sortedActivities)
        
        // 分析作息趨勢
        let routineTrend = analyzeRoutineTrend(sortedActivities)
        
        // 生成建議的作息時間表
        let suggestedSchedule = generateSuggestedSchedule(
            activities: sortedActivities,
            regularityScore: regularityScore,
            typicalCycles: typicalCycles
        )
        
        // 計算分析可信度
        let calendar = Calendar.current
        let days = Set(sortedActivities.map { calendar.startOfDay(for: $0.startTime) }).count
        let confidenceScore = calculateConfidenceScore(
            recordsCount: sortedActivities.count,
            daysCount: days
        )
        
        // 創建並返回結果
        return RoutinePatternResult(
            analyzedDateRange: dateRange,
            analyzedRecordsCount: sortedActivities.count,
            confidenceScore: confidenceScore,
            analysisTimestamp: Date(),
            regularityScore: regularityScore,
            routinePatternType: routinePatternType,
            typicalCycles: typicalCycles,
            activityDistribution: activityDistribution,
            routineTrend: routineTrend,
            suggestedSchedule: suggestedSchedule
        )
    }
    
    // 創建數據不足的結果
    private func createInsufficientDataResult(dateRange: ClosedRange<Date>, recordsCount: Int) -> RoutinePatternResult {
        return RoutinePatternResult(
            analyzedDateRange: dateRange,
            analyzedRecordsCount: recordsCount,
            confidenceScore: 0,
            analysisTimestamp: Date(),
            regularityScore: 0,
            routinePatternType: .insufficient,
            typicalCycles: [],
            activityDistribution: ActivityDistribution(
                sleepPercentage: 0,
                feedingPercentage: 0,
                playPercentage: 0,
                otherPercentage: 0,
                averageSleepDuration: 0,
                averageFeedingDuration: 0,
                averagePlayDuration: 0,
                averageOtherDuration: 0,
                averageSleepInterval: 0,
                averageFeedingInterval: 0
            ),
            routineTrend: .insufficient,
            suggestedSchedule: nil
        )
    }
    
    // MARK: - 分析方法
    
    // 計算作息規律性評分（0-100）
    private func calculateRegularityScore(_ activities: [ActivityRecord]) -> Int {
        let calendar = Calendar.current
        
        // 按活動類型和日期分組
        var activitiesByTypeAndDay: [ActivityType: [Date: [ActivityRecord]]] = [:]
        
        for activity in activities {
            let day = calendar.startOfDay(for: activity.startTime)
            if activitiesByTypeAndDay[activity.type] == nil {
                activitiesByTypeAndDay[activity.type] = [:]
            }
            if activitiesByTypeAndDay[activity.type]?[day] == nil {
                activitiesByTypeAndDay[activity.type]?[day] = []
            }
            activitiesByTypeAndDay[activity.type]?[day]?.append(activity)
        }
        
        // 計算每種活動的時間規律性
        var typeScores: [Double] = []
        
        for (type, dayActivities) in activitiesByTypeAndDay {
            // 只考慮有足夠數據的活動類型
            if dayActivities.count < minimumDaysForAnalysis {
                continue
            }
            
            // 計算每天該活動的平均開始時間
            var startTimesByDay: [Date: [Date]] = [:]
            for (day, activities) in dayActivities {
                startTimesByDay[day] = activities.map { $0.startTime }
            }
            
            // 計算每天的平均開始時間
            var averageStartTimesByDay: [Date: Date] = [:]
            for (day, startTimes) in startTimesByDay {
                if let avgTime = calculateAverageTime(startTimes) {
                    averageStartTimesByDay[day] = avgTime
                }
            }
            
            // 計算平均開始時間的標準差（分鐘）
            if averageStartTimesByDay.count >= minimumDaysForAnalysis {
                let times = Array(averageStartTimesByDay.values)
                if let referenceTime = calculateAverageTime(times) {
                    let stdDev = calculateTimeStandardDeviation(times: times, referenceTime: referenceTime)
                    
                    // 將標準差轉換為規律性評分（標準差越小，規律性越高）
                    let score = max(0, min(100, 100 - stdDev / 1.2))
                    typeScores.append(score)
                }
            }
        }
        
        // 計算總體規律性評分
     
(Content truncated due to size limit. Use line ranges to read in chunks)