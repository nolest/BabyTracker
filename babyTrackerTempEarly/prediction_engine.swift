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
  
(Content truncated due to size limit. Use line ranges to read in chunks)