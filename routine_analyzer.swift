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
        if typeScores.isEmpty {
            return 0
        } else {
            let avgScore = typeScores.reduce(0, +) / Double(typeScores.count)
            return Int(round(avgScore))
        }
    }
    
    // 計算平均時間
    private func calculateAverageTime(_ times: [Date]) -> Date? {
        guard !times.isEmpty else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 將所有時間轉換為分鐘數（相對於當天0點）
        var totalMinutes = 0
        for time in times {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            totalMinutes += minutes
        }
        
        // 計算平均分鐘數
        let avgMinutes = totalMinutes / times.count
        
        // 轉換回時間
        var components = DateComponents()
        components.hour = avgMinutes / 60
        components.minute = avgMinutes % 60
        
        return calendar.date(byAdding: components, to: today)
    }
    
    // 計算時間標準差（分鐘）
    private func calculateTimeStandardDeviation(times: [Date], referenceTime: Date) -> Double {
        let calendar = Calendar.current
        let referenceComponents = calendar.dateComponents([.hour, .minute], from: referenceTime)
        let referenceMinutes = (referenceComponents.hour ?? 0) * 60 + (referenceComponents.minute ?? 0)
        
        // 計算每個時間與參考時間的差異（分鐘）
        var differences: [Double] = []
        for time in times {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            
            // 處理跨日問題（例如，23:00 vs 01:00）
            var diff = Double(minutes - referenceMinutes)
            if diff > 12 * 60 {
                diff -= 24 * 60
            } else if diff < -12 * 60 {
                diff += 24 * 60
            }
            
            differences.append(abs(diff))
        }
        
        // 計算標準差
        let mean = differences.reduce(0, +) / Double(differences.count)
        let variance = differences.map { pow($0 - mean, 2) }.reduce(0, +) / Double(differences.count)
        return sqrt(variance)
    }
    
    // 判定作息模式類型
    private func determineRoutinePatternType(
        activities: [ActivityRecord],
        regularityScore: Int
    ) -> RoutinePatternType {
        // 檢查數據是否足夠
        let calendar = Calendar.current
        let days = Set(activities.map { calendar.startOfDay(for: $0.startTime) }).count
        
        guard activities.count >= minimumRecordsForAnalysis && days >= minimumDaysForAnalysis else {
            return .insufficient
        }
        
        // 檢查是否有明顯的趨勢變化
        let trend = analyzeRoutineTrend(activities)
        
        // 根據規律性評分判定模式類型
        if regularityScore >= 80 {
            return .highlyRegular
        } else if regularityScore >= 60 {
            return .moderatelyRegular
        } else if trend == .improving || trend == .declining {
            return .transitioning
        } else if days < minimumDaysForTrendAnalysis {
            return .evolving
        } else {
            return .irregular
        }
    }
    
    // 識別典型作息循環
    private func identifyTypicalCycles(_ activities: [ActivityRecord]) -> [RoutineCycle] {
        let calendar = Calendar.current
        
        // 按日期分組
        let activitiesByDay = Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.startTime)
        }
        
        // 對於每一天，識別活動序列
        var allSequences: [[ActivityType]] = []
        var allDurations: [TimeInterval] = []
        
        for (_, dayActivities) in activitiesByDay {
            // 按時間排序
            let sortedActivities = dayActivities.sorted { $0.startTime < $1.startTime }
            
            // 識別連續的活動序列
            var currentSequence: [ActivityType] = []
            var currentStart: Date?
            var currentEnd: Date?
            
            for activity in sortedActivities {
                // 如果是新序列的開始
                if currentSequence.isEmpty {
                    currentSequence.append(activity.type)
                    currentStart = activity.startTime
                    currentEnd = activity.endTime
                }
                // 如果是相同類型的活動，更新結束時間
                else if activity.type == currentSequence.last {
                    currentEnd = activity.endTime
                }
                // 如果是新類型的活動
                else {
                    currentSequence.append(activity.type)
                    currentEnd = activity.endTime
                    
                    // 如果形成了完整的循環（例如，睡眠-餵食-玩耍）
                    if currentSequence.count >= 3 {
                        // 檢查是否形成了循環（最後一個活動後面是第一個活動）
                        if let nextActivity = sortedActivities.first(where: { $0.startTime > activity.endTime }),
                           nextActivity.type == currentSequence.first {
                            // 記錄這個循環
                            allSequences.append(currentSequence)
                            
                            // 計算循環持續時間
                            if let start = currentStart, let end = currentEnd {
                                allDurations.append(end.timeIntervalSince(start))
                            }
                            
                            // 重置序列，從下一個活動開始
                            currentSequence = []
                            currentStart = nil
                            currentEnd = nil
                        }
                    }
                }
            }
        }
        
        // 統計循環頻率
        var cycleFrequency: [String: (count: Int, durations: [TimeInterval], days: Set<Date>)] = [:]
        
        for (i, sequence) in allSequences.enumerated() {
            let key = sequence.map { $0.rawValue }.joined(separator: "-")
            if cycleFrequency[key] == nil {
                cycleFrequency[key] = (0, [], [])
            }
            
            cycleFrequency[key]!.count += 1
            
            if i < allDurations.count {
                cycleFrequency[key]!.durations.append(allDurations[i])
            }
            
            // 記錄這個循環出現的日期
            if let firstActivity = activities.first(where: { $0.type == sequence.first }) {
                let day = calendar.startOfDay(for: firstActivity.startTime)
                cycleFrequency[key]!.days.insert(day)
            }
        }
        
        // 轉換為RoutineCycle對象
        var cycles: [RoutineCycle] = []
        
        for (key, data) in cycleFrequency {
            let sequenceTypes = key.split(separator: "-").compactMap { ActivityType(rawValue: String($0)) }
            
            // 計算平均持續時間
            let avgDuration = data.durations.isEmpty ? 0 : data.durations.reduce(0, +) / Double(data.durations.count)
            
            // 計算每天出現的平均次數
            let frequency = Double(data.count) / Double(data.days.count)
            
            // 計算規律性評分
            let regularityScore = calculateCycleRegularityScore(
                durations: data.durations,
                frequency: frequency
            )
            
            cycles.append(RoutineCycle(
                sequence: sequenceTypes,
                averageDuration: avgDuration,
                frequency: frequency,
                regularityScore: regularityScore
            ))
        }
        
        // 按頻率排序
        return cycles.sorted { $0.frequency > $1.frequency }
    }
    
    // 計算循環規律性評分
    private func calculateCycleRegularityScore(durations: [TimeInterval], frequency: Double) -> Int {
        guard !durations.isEmpty else {
            return 0
        }
        
        // 計算持續時間的變異係數
        let mean = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.map { pow($0 - mean, 2) }.reduce(0, +) / Double(durations.count)
        let stdDev = sqrt(variance)
        let cv = mean > 0 ? stdDev / mean : 0
        
        // 計算規律性評分
        let durationScore = max(0, min(100, 100 - cv * 100))
        
        // 頻率穩定性評分（頻率接近整數值得分高）
        let frequencyScore = max(0, min(100, 100 - abs(frequency - round(frequency)) * 100))
        
        // 加權平均
        return Int(round(durationScore * 0.7 + frequencyScore * 0.3))
    }
    
    // 計算活動時間分佈
    private func calculateActivityDistribution(_ activities: [ActivityRecord]) -> ActivityDistribution {
        // 計算每種活動的總時間
        var totalSleepTime: TimeInterval = 0
        var totalFeedingTime: TimeInterval = 0
        var totalPlayTime: TimeInterval = 0
        var totalOtherTime: TimeInterval = 0
        
        // 計算每種活動的次數
        var sleepCount = 0
        var feedingCount = 0
        var playCount = 0
        var otherCount = 0
        
        // 記錄每種活動的開始時間，用於計算間隔
        var sleepStartTimes: [Date] = []
        var feedingStartTimes: [Date] = []
        
        for activity in activities {
            let duration = activity.endTime.timeIntervalSince(activity.startTime)
            
            switch activity.type {
            case .sleep:
                totalSleepTime += duration
                sleepCount += 1
                sleepStartTimes.append(activity.startTime)
            case .feeding:
                totalFeedingTime += duration
                feedingCount += 1
                feedingStartTimes.append(activity.startTime)
            case .playtime, .tummyTime, .outdoors:
                totalPlayTime += duration
                playCount += 1
            default:
                totalOtherTime += duration
                otherCount += 1
            }
        }
        
        // 計算總時間
        let totalTime = totalSleepTime + totalFeedingTime + totalPlayTime + totalOtherTime
        
        // 計算百分比
        let sleepPercentage = totalTime > 0 ? totalSleepTime / totalTime : 0
        let feedingPercentage = totalTime > 0 ? totalFeedingTime / totalTime : 0
        let playPercentage = totalTime > 0 ? totalPlayTime / totalTime : 0
        let otherPercentage = totalTime > 0 ? totalOtherTime / totalTime : 0
        
        // 計算平均持續時間（小時）
        let averageSleepDuration = sleepCount > 0 ? totalSleepTime / Double(sleepCount) / 3600 : 0
        let averageFeedingDuration = feedingCount > 0 ? totalFeedingTime / Double(feedingCount) / 3600 : 0
        let averagePlayDuration = playCount > 0 ? totalPlayTime / Double(playCount) / 3600 : 0
        let averageOtherDuration = otherCount > 0 ? totalOtherTime / Double(otherCount) / 3600 : 0
        
        // 計算平均間隔時間（小時）
        let averageSleepInterval = calculateAverageInterval(sleepStartTimes) / 3600
        let averageFeedingInterval = calculateAverageInterval(feedingStartTimes) / 3600
        
        return ActivityDistribution(
            sleepPercentage: sleepPercentage,
            feedingPercentage: feedingPercentage,
            playPercentage: playPercentage,
            otherPercentage: otherPercentage,
            averageSleepDuration: averageSleepDuration,
            averageFeedingDuration: averageFeedingDuration,
            averagePlayDuration: averagePlayDuration,
            averageOtherDuration: averageOtherDuration,
            averageSleepInterval: averageSleepInterval,
            averageFeedingInterval: averageFeedingInterval
        )
    }
    
    // 計算平均間隔時間
    private func calculateAverageInterval(_ times: [Date]) -> TimeInterval {
        guard times.count >= 2 else {
            return 0
        }
        
        // 按時間排序
        let sortedTimes = times.sorted()
        
        // 計算相鄰時間點之間的間隔
        var intervals: [TimeInterval] = []
        for i in 0..<sortedTimes.count-1 {
            let interval = sortedTimes[i+1].timeIntervalSince(sortedTimes[i])
            
            // 只考慮合理的間隔（例如，小於24小時）
            if interval > 0 && interval < 24 * 3600 {
                intervals.append(interval)
            }
        }
        
        // 計算平均間隔
        return intervals.isEmpty ? 0 : intervals.reduce(0, +) / Double(intervals.count)
    }
    
    // 分析作息趨勢
    private func analyzeRoutineTrend(_ activities: [ActivityRecord]) -> RoutineTrend {
        // 檢查數據是否足夠
        let calendar = Calendar.current
        let days = Set(activities.map { calendar.startOfDay(for: $0.startTime) }).count
        
        guard activities.count >= minimumRecordsForTrendAnalysis && days >= minimumDaysForTrendAnalysis else {
            return .insufficient
        }
        
        // 按時間排序
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        
        // 將記錄分為前半部分和後半部分
        let midIndex = sortedActivities.count / 2
        let firstHalf = Array(sortedActivities[0..<midIndex])
        let secondHalf = Array(sortedActivities[midIndex...])
        
        // 計算兩個時期的規律性評分
        let firstHalfScore = calculateRegularityScore(firstHalf)
        let secondHalfScore = calculateRegularityScore(secondHalf)
        
        // 計算兩個時期的典型循環
        let firstHalfCycles = identifyTypicalCycles(firstHalf)
        let secondHalfCycles = identifyTypicalCycles(secondHalf)
        
        // 計算循環穩定性變化
        let firstHalfCycleStability = firstHalfCycles.isEmpty ? 0 : firstHalfCycles.map { $0.regularityScore }.reduce(0, +) / firstHalfCycles.count
        let secondHalfCycleStability = secondHalfCycles.isEmpty ? 0 : secondHalfCycles.map { $0.regularityScore }.reduce(0, +) / secondHalfCycles.count
        
        // 計算規律性變化
        let regularityChange = secondHalfScore - firstHalfScore
        let cycleStabilityChange = secondHalfCycleStability - firstHalfCycleStability
        
        // 綜合評估趨勢
        let trendScore = Double(regularityChange) * 0.7 + Double(cycleStabilityChange) * 0.3
        
        // 判定趨勢
        if trendScore > 10 {
            return .improving
        } else if trendScore < -10 {
            return .declining
        } else if abs(cycleStabilityChange) > 15 {
            return .fluctuating
        } else {
            return .stable
        }
    }
    
    // 生成建議的作息時間表
    private func generateSuggestedSchedule(
        activities: [ActivityRecord],
        regularityScore: Int,
        typicalCycles: [RoutineCycle]
    ) -> [ScheduleItem]? {
        // 只有當規律性評分足夠高時才生成建議
        guard regularityScore >= 50 && !typicalCycles.isEmpty else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 按活動類型分組
        let activitiesByType = Dictionary(grouping: activities) { $0.type }
        
        // 生成建議項目
        var scheduleItems: [ScheduleItem] = []
        
        // 處理主要活動類型
        for activityType in [ActivityType.sleep, .feeding, .playtime] {
            if let typeActivities = activitiesByType[activityType], !typeActivities.isEmpty {
                // 計算平均開始時間
                let startTimes = typeActivities.map { $0.startTime }
                if let avgStartTime = calculateAverageTime(startTimes) {
                    // 計算平均持續時間
                    let durations = typeActivities.map { $0.endTime.timeIntervalSince($0.startTime) }
                    let avgDuration = durations.reduce(0, +) / Double(durations.count)
                    
                    // 計算時間標準差，用於確定信心度
                    let stdDev = calculateTimeStandardDeviation(times: startTimes, referenceTime: avgStartTime)
                    let confidence = max(0.1, min(0.9, 1.0 - stdDev / 120.0))
                    
                    // 創建建議項目
                    scheduleItems.append(ScheduleItem(
                        activityType: activityType,
                        suggestedStartTime: avgStartTime,
                        suggestedDuration: avgDuration,
                        confidence: confidence
                    ))
                }
            }
        }
        
        // 按時間排序
        scheduleItems.sort { $0.suggestedStartTime < $1.suggestedStartTime }
        
        return scheduleItems
    }
    
    // 計算分析可信度
    private func calculateConfidenceScore(recordsCount: Int, daysCount: Int) -> Double {
        // 基於記錄數量的可信度
        let recordsConfidence = min(1.0, Double(recordsCount) / 50)
        
        // 基於日期範圍長度的可信度
        let daysConfidence = min(1.0, Double(daysCount) / 14)
        
        // 綜合可信度
        return (recordsConfidence * 0.6 + daysConfidence * 0.4)
    }
}

// 活動記錄（用於內部處理）
struct ActivityRecord {
    let id: String
    let type: ActivityType
    let startTime: Date
    let endTime: Date
    let notes: String?
}
