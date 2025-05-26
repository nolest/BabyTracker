// PredictionEngine.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：本地AI分析功能
// 預測引擎實現

import Foundation
import CoreData
import Accelerate

// MARK: - 預測結果
struct PredictionResult {
    // 基本信息
    let babyId: String
    let predictionTimestamp: Date
    let confidenceScore: Double // 預測可信度（0-1）
    
    // 睡眠預測
    let nextSleepPrediction: NextSleepPrediction?
    
    // 餵食預測
    let nextFeedingPrediction: NextFeedingPrediction?
    
    // 作息預測
    let nextActivityPrediction: NextActivityPrediction?
    
    // 預測依據
    let basedOnRecordsCount: Int
    let basedOnDaysCount: Int
    let basedOnPatternType: String
    
    // 預測有效期
    let validUntil: Date
}

// 下次睡眠預測
struct NextSleepPrediction {
    let earliestStartTime: Date // 最早可能開始時間
    let latestStartTime: Date // 最晚可能開始時間
    let expectedDuration: TimeInterval // 預期持續時間（秒）
    let durationVariance: TimeInterval // 持續時間變異（秒）
    let confidence: Double // 預測可信度（0-1）
    
    // 預測窗口中心時間
    var centerTime: Date {
        return earliestStartTime.addingTimeInterval(latestStartTime.timeIntervalSince(earliestStartTime) / 2)
    }
    
    // 預測窗口寬度（分鐘）
    var windowWidth: Double {
        return latestStartTime.timeIntervalSince(earliestStartTime) / 60
    }
    
    // 格式化的預測時間範圍
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let earliestString = formatter.string(from: earliestStartTime)
        let latestString = formatter.string(from: latestStartTime)
        
        return "\(earliestString) - \(latestString)"
    }
    
    // 格式化的預期持續時間
    var formattedDuration: String {
        let hours = Int(expectedDuration / 3600)
        let minutes = Int((expectedDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return String(format: NSLocalizedString("%d小時%d分鐘", comment: "Formatted duration with hours and minutes"), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%d分鐘", comment: "Formatted duration with minutes only"), minutes)
        }
    }
    
    // 本地化描述
    var localizedDescription: String {
        return String(format: NSLocalizedString("預計下次睡眠時間：%@（持續%@）", comment: "Next sleep prediction description"),
                      formattedTimeRange, formattedDuration)
    }
}

// 下次餵食預測
struct NextFeedingPrediction {
    let earliestStartTime: Date // 最早可能開始時間
    let latestStartTime: Date // 最晚可能開始時間
    let expectedDuration: TimeInterval // 預期持續時間（秒）
    let confidence: Double // 預測可信度（0-1）
    
    // 預測窗口中心時間
    var centerTime: Date {
        return earliestStartTime.addingTimeInterval(latestStartTime.timeIntervalSince(earliestStartTime) / 2)
    }
    
    // 預測窗口寬度（分鐘）
    var windowWidth: Double {
        return latestStartTime.timeIntervalSince(earliestStartTime) / 60
    }
    
    // 格式化的預測時間範圍
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let earliestString = formatter.string(from: earliestStartTime)
        let latestString = formatter.string(from: latestStartTime)
        
        return "\(earliestString) - \(latestString)"
    }
    
    // 本地化描述
    var localizedDescription: String {
        return String(format: NSLocalizedString("預計下次餵食時間：%@", comment: "Next feeding prediction description"),
                      formattedTimeRange)
    }
}

// 下次活動預測
struct NextActivityPrediction {
    let activityType: ActivityType
    let earliestStartTime: Date // 最早可能開始時間
    let latestStartTime: Date // 最晚可能開始時間
    let confidence: Double // 預測可信度（0-1）
    
    // 預測窗口中心時間
    var centerTime: Date {
        return earliestStartTime.addingTimeInterval(latestStartTime.timeIntervalSince(earliestStartTime) / 2)
    }
    
    // 預測窗口寬度（分鐘）
    var windowWidth: Double {
        return latestStartTime.timeIntervalSince(earliestStartTime) / 60
    }
    
    // 格式化的預測時間範圍
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let earliestString = formatter.string(from: earliestStartTime)
        let latestString = formatter.string(from: latestStartTime)
        
        return "\(earliestString) - \(latestString)"
    }
    
    // 本地化描述
    var localizedDescription: String {
        return String(format: NSLocalizedString("預計下次%@時間：%@", comment: "Next activity prediction description"),
                      activityType.localizedName, formattedTimeRange)
    }
}

// MARK: - 預測引擎
class PredictionEngine {
    // 依賴
    private let sleepRepository: SleepRecordRepository
    private let feedingRepository: FeedingRepository
    private let activityRepository: ActivityRepository
    private let sleepPatternAnalyzer: SleepPatternAnalyzer
    private let routineAnalyzer: RoutineAnalyzer
    
    // 常量
    private let minimumRecordsForPrediction = 7 // 進行預測所需的最少記錄數
    private let minimumDaysForPrediction = 3 // 進行預測所需的最少天數
    private let predictionValidityHours = 12 // 預測有效期（小時）
    
    // 初始化
    init(
        sleepRepository: SleepRecordRepository,
        feedingRepository: FeedingRepository,
        activityRepository: ActivityRepository,
        sleepPatternAnalyzer: SleepPatternAnalyzer,
        routineAnalyzer: RoutineAnalyzer
    ) {
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
        self.activityRepository = activityRepository
        self.sleepPatternAnalyzer = sleepPatternAnalyzer
        self.routineAnalyzer = routineAnalyzer
    }
    
    // 預測下次睡眠
    func predictNextSleep(babyId: String) async -> Result<PredictionResult, Error> {
        do {
            // 獲取分析時間範圍（過去14天）
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
            let dateRange = startDate...endDate
            
            // 獲取睡眠記錄
            let sleepRecordsResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
            
            switch sleepRecordsResult {
            case .success(let sleepRecords):
                // 檢查記錄數量是否足夠
                guard sleepRecords.count >= minimumRecordsForPrediction else {
                    return .success(createInsufficientDataResult(babyId: babyId))
                }
                
                // 檢查天數是否足夠
                let calendar = Calendar.current
                let days = Set(sleepRecords.map { calendar.startOfDay(for: $0.startTime) }).count
                guard days >= minimumDaysForPrediction else {
                    return .success(createInsufficientDataResult(babyId: babyId))
                }
                
                // 分析睡眠模式
                let sleepPatternResult = await sleepPatternAnalyzer.analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
                
                switch sleepPatternResult {
                case .success(let sleepPattern):
                    // 預測下次睡眠
                    let nextSleepPrediction = predictNextSleepFromPattern(sleepRecords: sleepRecords, sleepPattern: sleepPattern)
                    
                    // 預測下次餵食（如果有餵食記錄）
                    let nextFeedingPrediction = await predictNextFeeding(babyId: babyId, dateRange: dateRange)
                    
                    // 預測下次活動
                    let nextActivityPrediction = await predictNextActivity(babyId: babyId, dateRange: dateRange)
                    
                    // 創建預測結果
                    return .success(PredictionResult(
                        babyId: babyId,
                        predictionTimestamp: Date(),
                        confidenceScore: calculateOverallConfidence(
                            sleepConfidence: nextSleepPrediction?.confidence ?? 0,
                            feedingConfidence: nextFeedingPrediction?.confidence ?? 0,
                            activityConfidence: nextActivityPrediction?.confidence ?? 0,
                            patternConfidence: sleepPattern.confidenceScore
                        ),
                        nextSleepPrediction: nextSleepPrediction,
                        nextFeedingPrediction: nextFeedingPrediction,
                        nextActivityPrediction: nextActivityPrediction,
                        basedOnRecordsCount: sleepRecords.count,
                        basedOnDaysCount: days,
                        basedOnPatternType: sleepPattern.sleepPatternType.rawValue,
                        validUntil: Calendar.current.date(byAdding: .hour, value: predictionValidityHours, to: Date()) ?? Date()
                    ))
                    
                case .failure(let error):
                    return .failure(error)
                }
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    
    // 創建數據不足的結果
    private func createInsufficientDataResult(babyId: String) -> PredictionResult {
        return PredictionResult(
            babyId: babyId,
            predictionTimestamp: Date(),
            confidenceScore: 0,
            nextSleepPrediction: nil,
            nextFeedingPrediction: nil,
            nextActivityPrediction: nil,
            basedOnRecordsCount: 0,
            basedOnDaysCount: 0,
            basedOnPatternType: "insufficient",
            validUntil: Date()
        )
    }
    
    // MARK: - 預測方法
    
    // 從睡眠模式預測下次睡眠
    private func predictNextSleepFromPattern(sleepRecords: [SleepRecord], sleepPattern: SleepPatternResult) -> NextSleepPrediction? {
        // 檢查是否有足夠的數據進行預測
        guard sleepRecords.count >= minimumRecordsForPrediction,
              sleepPattern.sleepPatternType != .insufficient else {
            return nil
        }
        
        // 獲取當前時間
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeMinutes = currentHour * 60 + currentMinute
        
        // 按時間排序
        let sortedRecords = sleepRecords.sorted { $0.startTime < $1.startTime }
        
        // 獲取最近的睡眠記錄
        guard let lastSleep = sortedRecords.last else {
            return nil
        }
        
        // 檢查是否正在睡眠中
        if lastSleep.endTime > now {
            // 正在睡眠中，預測醒來時間
            return predictWakeUpTime(lastSleep: lastSleep, sleepPattern: sleepPattern)
        }
        
        // 預測下次睡眠時間
        
        // 方法1：基於平均間隔
        let nextSleepByInterval = predictNextSleepByInterval(
            lastSleep: lastSleep,
            sleepRecords: sortedRecords,
            currentTimeMinutes: currentTimeMinutes
        )
        
        // 方法2：基於時間模式
        let nextSleepByTimePattern = predictNextSleepByTimePattern(
            sleepRecords: sortedRecords,
            currentTimeMinutes: currentTimeMinutes
        )
        
        // 方法3：基於作息循環
        let nextSleepByCycle = predictNextSleepByCycle(
            lastSleep: lastSleep,
            sleepRecords: sortedRecords,
            currentTimeMinutes: currentTimeMinutes
        )
        
        // 綜合多種預測方法的結果
        return combineNextSleepPredictions(
            intervalPrediction: nextSleepByInterval,
            timePatternPrediction: nextSleepByTimePattern,
            cyclePrediction: nextSleepByCycle,
            patternType: sleepPattern.sleepPatternType,
            regularityScore: sleepPattern.regularityScore
        )
    }
    
    // 預測醒來時間
    private func predictWakeUpTime(lastSleep: SleepRecord, sleepPattern: SleepPatternResult) -> NextSleepPrediction? {
        // 計算已經睡眠的時間
        let now = Date()
        let sleepDurationSoFar = now.timeIntervalSince(lastSleep.startTime)
        
        // 獲取平均睡眠時長
        let avgSleepDuration = sleepPattern.averageSleepDuration * 3600 // 轉換為秒
        
        // 如果已經超過平均睡眠時長，預測很快會醒來
        if sleepDurationSoFar >= avgSleepDuration {
            let earliestWakeUp = now
            let latestWakeUp = now.addingTimeInterval(15 * 60) // 15分鐘內
            
            return NextSleepPrediction(
                earliestStartTime: earliestWakeUp,
                latestStartTime: latestWakeUp,
                expectedDuration: sleepDurationSoFar,
                durationVariance: 15 * 60,
                confidence: 0.7
            )
        }
        
        // 否則，基於平均睡眠時長預測醒來時間
        let expectedTotalDuration = avgSleepDuration
        let remainingDuration = max(0, expectedTotalDuration - sleepDurationSoFar)
        
        let earliestWakeUp = now.addingTimeInterval(max(0, remainingDuration * 0.8))
        let latestWakeUp = now.addingTimeInterval(remainingDuration * 1.2)
        
        return NextSleepPrediction(
            earliestStartTime: earliestWakeUp,
            latestStartTime: latestWakeUp,
            expectedDuration: expectedTotalDuration,
            durationVariance: expectedTotalDuration * 0.2,
            confidence: min(0.9, sleepPattern.confidenceScore)
        )
    }
    
    // 基於平均間隔預測下次睡眠
    private func predictNextSleepByInterval(
        lastSleep: SleepRecord,
        sleepRecords: [SleepRecord],
        currentTimeMinutes: Int
    ) -> NextSleepPrediction? {
        // 計算平均睡眠間隔
        var intervals: [TimeInterval] = []
        
        for i in 0..<sleepRecords.count-1 {
            let interval = sleepRecords[i+1].startTime.timeIntervalSince(sleepRecords[i].endTime)
            if interval > 0 && interval < 24 * 3600 { // 只考慮24小時內的間隔
                intervals.append(interval)
            }
        }
        
        guard !intervals.isEmpty else {
            return nil
        }
        
        // 計算平均間隔和標準差
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        
        // 計算預測時間
        let lastSleepEnd = lastSleep.endTime
        let predictedNextStart = lastSleepEnd.addingTimeInterval(avgInterval)
        
        // 如果預測時間已經過去，調整為未來的時間
        let now = Date()
        let adjustedPredictedStart = predictedNextStart < now ? now.addingTimeInterval(avgInterval / 2) : predictedNextStart
        
        // 設置預測窗口
        let windowWidth = max(30 * 60, stdDev) // 至少30分鐘
        let earliestStart = adjustedPredictedStart.addingTimeInterval(-windowWidth / 2)
        let latestStart = adjustedPredictedStart.addingTimeInterval(windowWidth / 2)
        
        // 計算平均睡眠時長
        let durations = sleepRecords.map { $0.endTime.timeIntervalSince($0.startTime) }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let durationVariance = durations.map { pow($0 - avgDuration, 2) }.reduce(0, +) / Double(durations.count)
        let durationStdDev = sqrt(durationVariance)
        
        // 計算可信度
        let intervalVariability = stdDev / avgInterval
        let confidence = max(0.3, min(0.8, 1.0 - intervalVariability))
        
        return NextSleepPrediction(
            earliestStartTime: earliestStart,
            latestStartTime: latestStart,
            expectedDuration: avgDuration,
            durationVariance: durationStdDev,
            confidence: confidence
        )
    }
    
    // 基於時間模式預測下次睡眠
    private func predictNextSleepByTimePattern(
        sleepRecords: [SleepRecord],
        currentTimeMinutes: Int
    ) -> NextSleepPrediction? {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 將所有睡眠開始時間轉換為分鐘數（相對於當天0點）
        var startTimeMinutes: [Int] = []
        for record in sleepRecords {
            let components = calendar.dateComponents([.hour, .minute], from: record.startTime)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            startTimeMinutes.append(minutes)
        }
        
        // 按時間排序
        startTimeMinutes.sort()
        
        // 找出下一個可能的睡眠時間（大於當前時間的最小值）
        var nextSleepMinutes = startTimeMinutes.first { $0 > currentTimeMinutes }
        
        // 如果沒有找到，則考慮第二天的第一個睡眠時間
        if nextSleepMinutes == nil && !startTimeMinutes.isEmpty {
            nextSleepMinutes = startTimeMinutes.first
            // 調整為第二天
            nextSleepMinutes = nextSleepMinutes! + 24 * 60
        }
        
        guard let nextMinutes = nextSleepMinutes else {
            return nil
        }
        
        // 計算預測時間的標準差
        let relevantTimes = startTimeMinutes.filter { abs($0 - nextMinutes) < 120 || abs($0 - nextMinutes + 24 * 60) < 120 }
        guard !relevantTimes.isEmpty else {
            return nil
        }
        
        let avgMinutes = relevantTimes.reduce(0, +) / relevantTimes.count
        let variance = relevantTimes.map { pow(Double($0 - avgMinutes), 2) }.reduce(0, +) / Double(relevantTimes.count)
        let stdDev = sqrt(variance)
        
        // 創建預測時間
        var predictedComponents = DateComponents()
        predictedComponents.hour = avgMinutes / 60
        predictedComponents.minute = avgMinutes % 60
        
        // 如果預測時間已經過去，調整為明天
        let predictedDate = calendar.date(byAdding: predictedComponents, to: today) ?? now
        let adjustedDate = predictedDate < now ? calendar.date(byAdding: .day, value: 1, to: predictedDate) ?? now : predictedDate
        
        // 設置預測窗口
        let windowWidth = max(30.0, stdDev * 2) // 至少30分鐘
        let earliestStart = calendar.date(byAdding: .minute, value: -Int(windowWidth / 2), to: adjustedDate) ?? adjustedDate
        let latestStart = calendar.date(byAdding: .minute, value: Int(windowWidth / 2), to: adjustedDate) ?? adjustedDate
        
        // 計算平均睡眠時長
        let durations = sleepRecords.map { $0.endTime.timeIntervalSince($0.startTime) }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let durationVariance = durations.map { pow($0 - avgDuration, 2) }.reduce(0, +) / Double(durations.count)
        let durationStdDev = sqrt(durationVariance)
        
        // 計算可信度
        let timeVariability = stdDev / 60 // 轉換為小時
        let confidence = max(0.4, min(0.9, 1.0 - timeVariability / 3))
        
        return NextSleepPrediction(
            earliestStartTime: earliestStart,
            latestStartTime: latestStart,
            expectedDuration: avgDuration,
            durationVariance: durationStdDev,
            confidence: confidence
        )
    }
    
    // 基於作息循環預測下次睡眠
    private func predictNextSleepByCycle(
        lastSleep: SleepRecord,
        sleepRecords: [SleepRecord],
        currentTimeMinutes: Int
    ) -> NextSleepPrediction? {
        // 這個方法需要更複雜的作息循環分析，這裡提供一個簡化版本
        // 在實際應用中，應該結合RoutineAnalyzer的結果
        
        // 計算平均睡眠-清醒-睡眠循環
        let calendar = Calendar.current
        var cycleIntervals: [TimeInterval] = []
        
        for i in 0..<sleepRecords.count-1 {
            let interval = sleepRecords[i+1].startTime.timeIntervalSince(sleepRecords[i].startTime)
            if interval > 0 && interval < 36 * 3600 { // 只考慮36小時內的循環
                cycleIntervals.append(interval)
            }
        }
        
        guard !cycleIntervals.isEmpty else {
            return nil
        }
        
        // 計算平均循環間隔和標準差
        let avgCycleInterval = cycleIntervals.reduce(0, +) / Double(cycleIntervals.count)
        let variance = cycleIntervals.map { pow($0 - avgCycleInterval, 2) }.reduce(0, +) / Double(cycleIntervals.count)
        let stdDev = sqrt(variance)
        
        // 計算預測時間
        let predictedNextStart = lastSleep.startTime.addingTimeInterval(avgCycleInterval)
        
        // 如果預測時間已經過去，調整為未來的時間
        let now = Date()
        let adjustedPredictedStart = predictedNextStart < now ? now.addingTimeInterval(avgCycleInterval / 3) : predictedNextStart
        
        // 設置預測窗口
        let windowWidth = max(45 * 60, stdDev / 2) // 至少45分鐘
        let earliestStart = adjustedPredictedStart.addingTimeInterval(-windowWidth / 2)
        let latestStart = adjustedPredictedStart.addingTimeInterval(windowWidth / 2)
        
        // 計算平均睡眠時長
        let durations = sleepRecords.map { $0.endTime.timeIntervalSince($0.startTime) }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let durationVariance = durations.map { pow($0 - avgDuration, 2) }.reduce(0, +) / Double(durations.count)
        let durationStdDev = sqrt(durationVariance)
        
        // 計算可信度
        let cycleVariability = stdDev / avgCycleInterval
        let confidence = max(0.3, min(0.8, 1.0 - cycleVariability))
        
        return NextSleepPrediction(
            earliestStartTime: earliestStart,
            latestStartTime: latestStart,
            expectedDuration: avgDuration,
            durationVariance: durationStdDev,
            confidence: confidence
        )
    }
    
    // 綜合多種預測方法的結果
    private func combineNextSleepPredictions(
        intervalPrediction: NextSleepPrediction?,
        timePatternPrediction: NextSleepPrediction?,
        cyclePrediction: NextSleepPrediction?,
        patternType: SleepPatternType,
        regularityScore: Int
    ) -> NextSleepPrediction? {
        // 檢查是否有足夠的預測結果
        var validPredictions: [NextSleepPrediction] = []
        if let prediction = intervalPrediction { validPredictions.append(prediction) }
        if let prediction = timePatternPrediction { validPredictions.append(prediction) }
        if let prediction = cyclePrediction { validPredictions.append(prediction) }
        
        guard !validPredictions.isEmpty else {
            return nil
        }
        
        // 根據睡眠模式類型和規律性評分調整權重
        var intervalWeight = 0.3
        var timePatternWeight = 0.4
        var cycleWeight = 0.3
        
        switch patternType {
        case .highlyRegular:
            timePatternWeight = 0.5
            intervalWeight = 0.2
            cycleWeight = 0.3
        case .moderatelyRegular:
            timePatternWeight = 0.4
            intervalWeight = 0.3
            cycleWeight = 0.3
        case .irregular:
            timePatternWeight = 0.3
            intervalWeight = 0.4
            cycleWeight = 0.3
        case .evolving, .transitioning:
            timePatternWeight = 0.3
            intervalWeight = 0.3
            cycleWeight = 0.4
        case .insufficient:
            timePatternWeight = 0.33
            intervalWeight = 0.33
            cycleWeight = 0.34
        }
        
        // 調整權重以反映規律性評分
        let regularityFactor = Double(regularityScore) / 100.0
        timePatternWeight *= regularityFactor
        
        // 重新歸一化權重
        let totalWeight = timePatternWeight + intervalWeight + cycleWeight
        timePatternWeight /= totalWeight
        intervalWeight /= totalWeight
        cycleWeight /= totalWeight
        
        // 計算加權平均預測時間
        var weightedEarliestTime: TimeInterval = 0
        var weightedLatestTime: TimeInterval = 0
        var weightedDuration: TimeInterval = 0
        var weightedDurationVariance: TimeInterval = 0
        var totalConfidence: Double = 0
        var totalWeightApplied: Double = 0
        
        let now = Date().timeIntervalSince1970
        
        if let prediction = intervalPrediction {
            let weight = intervalWeight * prediction.confidence
            weightedEarliestTime += prediction.earliestStartTime.timeIntervalSince1970 * weight
            weightedLatestTime += prediction.latestStartTime.timeIntervalSince1970 * weight
            weightedDuration += prediction.expectedDuration * weight
            weightedDurationVariance += prediction.durationVariance * weight
            totalConfidence += prediction.confidence * intervalWeight
            totalWeightApplied += weight
        }
        
        if let prediction = timePatternPrediction {
            let weight = timePatternWeight * prediction.confidence
            weightedEarliestTime += prediction.earliestStartTime.timeIntervalSince1970 * weight
            weightedLatestTime += prediction.latestStartTime.timeIntervalSince1970 * weight
            weightedDuration += prediction.expectedDuration * weight
            weightedDurationVariance += prediction.durationVariance * weight
            totalConfidence += prediction.confidence * timePatternWeight
            totalWeightApplied += weight
        }
        
        if let prediction = cyclePrediction {
            let weight = cycleWeight * prediction.confidence
            weightedEarliestTime += prediction.earliestStartTime.timeIntervalSince1970 * weight
            weightedLatestTime += prediction.latestStartTime.timeIntervalSince1970 * weight
            weightedDuration += prediction.expectedDuration * weight
            weightedDurationVariance += prediction.durationVariance * weight
            totalConfidence += prediction.confidence * cycleWeight
            totalWeightApplied += weight
        }
        
        // 避免除以零
        guard totalWeightApplied > 0 else {
            return validPredictions.first
        }
        
        // 計算最終預測結果
        let finalEarliestTime = Date(timeIntervalSince1970: weightedEarliestTime / totalWeightApplied)
        let finalLatestTime = Date(timeIntervalSince1970: weightedLatestTime / totalWeightApplied)
        let finalDuration = weightedDuration / totalWeightApplied
        let finalDurationVariance = weightedDurationVariance / totalWeightApplied
        
        // 確保預測時間在未來
        let now = Date()
        let adjustedEarliestTime = finalEarliestTime < now ? now : finalEarliestTime
        let adjustedLatestTime = finalLatestTime < now ? now.addingTimeInterval(30 * 60) : finalLatestTime
        
        // 確保最早時間不晚於最晚時間
        let validEarliestTime = adjustedEarliestTime < adjustedLatestTime ? adjustedEarliestTime : adjustedLatestTime.addingTimeInterval(-30 * 60)
        
        return NextSleepPrediction(
            earliestStartTime: validEarliestTime,
            latestStartTime: adjustedLatestTime,
            expectedDuration: finalDuration,
            durationVariance: finalDurationVariance,
            confidence: totalConfidence
        )
    }
    
    // 預測下次餵食
    private func predictNextFeeding(babyId: String, dateRange: ClosedRange<Date>) async -> NextFeedingPrediction? {
        // 獲取餵食記錄
        let feedingRecordsResult = await feedingRepository.getFeedingRecords(babyId: babyId, dateRange: dateRange)
        
        switch feedingRecordsResult {
        case .success(let feedingRecords):
            // 檢查記錄數量是否足夠
            guard feedingRecords.count >= minimumRecordsForPrediction else {
                return nil
            }
            
            // 按時間排序
            let sortedRecords = feedingRecords.sorted { $0.startTime < $1.startTime }
            
            // 獲取最近的餵食記錄
            guard let lastFeeding = sortedRecords.last else {
                return nil
            }
            
            // 計算平均餵食間隔
            var intervals: [TimeInterval] = []
            
            for i in 0..<sortedRecords.count-1 {
                let interval = sortedRecords[i+1].startTime.timeIntervalSince(sortedRecords[i].startTime)
                if interval > 0 && interval < 12 * 3600 { // 只考慮12小時內的間隔
                    intervals.append(interval)
                }
            }
            
            guard !intervals.isEmpty else {
                return nil
            }
            
            // 計算平均間隔和標準差
            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
            let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
            let stdDev = sqrt(variance)
            
            // 計算預測時間
            let predictedNextStart = lastFeeding.startTime.addingTimeInterval(avgInterval)
            
            // 如果預測時間已經過去，調整為未來的時間
            let now = Date()
            let adjustedPredictedStart = predictedNextStart < now ? now.addingTimeInterval(avgInterval / 3) : predictedNextStart
            
            // 設置預測窗口
            let windowWidth = max(20 * 60, stdDev / 2) // 至少20分鐘
            let earliestStart = adjustedPredictedStart.addingTimeInterval(-windowWidth / 2)
            let latestStart = adjustedPredictedStart.addingTimeInterval(windowWidth / 2)
            
            // 計算平均餵食時長
            let durations = sortedRecords.compactMap { record in
                if let endTime = record.endTime {
                    return endTime.timeIntervalSince(record.startTime)
                }
                return nil
            }
            
            let avgDuration = durations.isEmpty ? 20 * 60 : durations.reduce(0, +) / Double(durations.count)
            
            // 計算可信度
            let intervalVariability = stdDev / avgInterval
            let confidence = max(0.3, min(0.8, 1.0 - intervalVariability))
            
            return NextFeedingPrediction(
                earliestStartTime: earliestStart,
                latestStartTime: latestStart,
                expectedDuration: avgDuration,
                confidence: confidence
            )
            
        case .failure:
            return nil
        }
    }
    
    // 預測下次活動
    private func predictNextActivity(babyId: String, dateRange: ClosedRange<Date>) async -> NextActivityPrediction? {
        // 獲取活動記錄
        let activitiesResult = await activityRepository.getActivities(babyId: babyId, dateRange: dateRange)
        
        switch activitiesResult {
        case .success(let activities):
            // 檢查記錄數量是否足夠
            guard activities.count >= minimumRecordsForPrediction else {
                return nil
            }
            
            // 按時間排序
            let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
            
            // 按活動類型分組
            let activitiesByType = Dictionary(grouping: sortedActivities) { $0.type }
            
            // 找出最常見的活動類型
            var mostCommonType: ActivityType?
            var maxCount = 0
            
            for (type, typeActivities) in activitiesByType {
                if typeActivities.count > maxCount {
                    maxCount = typeActivities.count
                    mostCommonType = type
                }
            }
            
            guard let activityType = mostCommonType,
                  let typeActivities = activitiesByType[activityType],
                  typeActivities.count >= minimumRecordsForPrediction / 2 else {
                return nil
            }
            
            // 獲取最近的該類型活動
            guard let lastActivity = typeActivities.last else {
                return nil
            }
            
            // 計算平均活動間隔
            var intervals: [TimeInterval] = []
            
            for i in 0..<typeActivities.count-1 {
                let interval = typeActivities[i+1].startTime.timeIntervalSince(typeActivities[i].startTime)
                if interval > 0 && interval < 24 * 3600 { // 只考慮24小時內的間隔
                    intervals.append(interval)
                }
            }
            
            guard !intervals.isEmpty else {
                return nil
            }
            
            // 計算平均間隔和標準差
            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
            let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
            let stdDev = sqrt(variance)
            
            // 計算預測時間
            let predictedNextStart = lastActivity.startTime.addingTimeInterval(avgInterval)
            
            // 如果預測時間已經過去，調整為未來的時間
            let now = Date()
            let adjustedPredictedStart = predictedNextStart < now ? now.addingTimeInterval(avgInterval / 3) : predictedNextStart
            
            // 設置預測窗口
            let windowWidth = max(30 * 60, stdDev / 2) // 至少30分鐘
            let earliestStart = adjustedPredictedStart.addingTimeInterval(-windowWidth / 2)
            let latestStart = adjustedPredictedStart.addingTimeInterval(windowWidth / 2)
            
            // 計算可信度
            let intervalVariability = stdDev / avgInterval
            let confidence = max(0.3, min(0.7, 1.0 - intervalVariability))
            
            return NextActivityPrediction(
                activityType: activityType,
                earliestStartTime: earliestStart,
                latestStartTime: latestStart,
                confidence: confidence
            )
            
        case .failure:
            return nil
        }
    }
    
    // 計算整體預測可信度
    private func calculateOverallConfidence(
        sleepConfidence: Double,
        feedingConfidence: Double,
        activityConfidence: Double,
        patternConfidence: Double
    ) -> Double {
        // 加權平均
        let sleepWeight = 0.5
        let feedingWeight = 0.3
        let activityWeight = 0.1
        let patternWeight = 0.1
        
        var totalWeight = 0.0
        var weightedConfidence = 0.0
        
        if sleepConfidence > 0 {
            weightedConfidence += sleepConfidence * sleepWeight
            totalWeight += sleepWeight
        }
        
        if feedingConfidence > 0 {
            weightedConfidence += feedingConfidence * feedingWeight
            totalWeight += feedingWeight
        }
        
        if activityConfidence > 0 {
            weightedConfidence += activityConfidence * activityWeight
            totalWeight += activityWeight
        }
        
        if patternConfidence > 0 {
            weightedConfidence += patternConfidence * patternWeight
            totalWeight += patternWeight
        }
        
        return totalWeight > 0 ? weightedConfidence / totalWeight : 0
    }
}
