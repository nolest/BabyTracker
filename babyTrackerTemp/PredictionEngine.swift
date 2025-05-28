import Foundation

/// 預測引擎
class PredictionEngine {
    // MARK: - 依賴
    private let sleepRepository: SleepRecordRepositoryProtocol
    private let feedingRepository: FeedingRepositoryProtocol
    private let activityRepository: ActivityRepositoryProtocol
    private let sleepPatternAnalyzer: SleepPatternAnalyzer
    private let routineAnalyzer: RoutineAnalyzer
    
    // MARK: - 初始化
    
    init(sleepRepository: SleepRecordRepositoryProtocol,
         feedingRepository: FeedingRepositoryProtocol,
         activityRepository: ActivityRepositoryProtocol,
         sleepPatternAnalyzer: SleepPatternAnalyzer,
         routineAnalyzer: RoutineAnalyzer) {
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
        self.activityRepository = activityRepository
        self.sleepPatternAnalyzer = sleepPatternAnalyzer
        self.routineAnalyzer = routineAnalyzer
    }
    
    // MARK: - 公開方法
    
    /// 預測下一次睡眠
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 用於分析的日期範圍
    /// - Returns: 預測結果或錯誤
    func predictNextSleep(babyId: String, dateRange: ClosedRange<Date>) async -> Result<PredictionResult, AnalysisError> {
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
        if sleepRecords.isEmpty {
            return .failure(.insufficientData)
        }
        
        // 執行本地預測
        return .success(predictLocally(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities
        ))
    }
    
    // MARK: - 私有方法
    
    /// 本地預測下一次睡眠
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    /// - Returns: 預測結果
    private func predictLocally(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity]
    ) -> PredictionResult {
        // 預測下一次睡眠時間
        let sleepPredictions = predictNextSleepTimes(sleepRecords)
        
        // 預測下一次餵食時間
        let feedingPredictions = predictNextFeedingTimes(feedingRecords)
        
        // 計算置信度分數
        let confidenceScore = calculateConfidenceScore(
            sleepRecords: sleepRecords,
            feedingRecords: feedingRecords,
            activities: activities
        )
        
        return PredictionResult(
            id: UUID().uuidString,
            predictionTime: Date(),
            sleepPredictions: sleepPredictions,
            feedingPredictions: feedingPredictions,
            confidenceScore: confidenceScore
        )
    }
    
    /// 預測下一次睡眠時間
    /// - Parameter sleepRecords: 睡眠記錄
    /// - Returns: 睡眠預測列表
    private func predictNextSleepTimes(_ sleepRecords: [SleepRecord]) -> [PredictionResult.SleepPrediction] {
        // 按開始時間排序
        let sortedRecords = sleepRecords.sorted { $0.startTime < $1.startTime }
        
        // 分離日間和夜間睡眠
        let daySleepRecords = sortedRecords.filter { !$0.isNightSleep }
        let nightSleepRecords = sortedRecords.filter { $0.isNightSleep }
        
        var predictions: [PredictionResult.SleepPrediction] = []
        
        // 預測下一次夜間睡眠
        if !nightSleepRecords.isEmpty {
            let prediction = predictNextSleepTime(nightSleepRecords, isNight: true)
            predictions.append(prediction)
        }
        
        // 預測下一次日間睡眠
        if !daySleepRecords.isEmpty {
            let prediction = predictNextSleepTime(daySleepRecords, isNight: false)
            predictions.append(prediction)
        }
        
        return predictions
    }
    
    /// 預測下一次睡眠時間
    /// - Parameters:
    ///   - records: 睡眠記錄
    ///   - isNight: 是否為夜間睡眠
    /// - Returns: 睡眠預測
    private func predictNextSleepTime(_ records: [SleepRecord], isNight: Bool) -> PredictionResult.SleepPrediction {
        // 計算平均開始時間（小時）
        let calendar = Calendar.current
        let hourComponents = records.map { calendar.component(.hour, from: $0.startTime) }
        let averageHour = hourComponents.reduce(0, +) / hourComponents.count
        
        // 計算平均持續時間
        let averageDuration = records.reduce(0.0) { $0 + $1.duration } / Double(records.count)
        
        // 創建下一次預測時間
        let now = Date()
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = averageHour
        dateComponents.minute = 0
        dateComponents.second = 0
        
        // 如果預測時間已過，則設置為明天
        var predictedDate = calendar.date(from: dateComponents) ?? now
        if predictedDate < now {
            predictedDate = calendar.date(byAdding: .day, value: 1, to: predictedDate) ?? now
        }
        
        // 設置置信度
        let confidence = isNight ? 0.8 : 0.6
        
        return PredictionResult.SleepPrediction(
            predictedStartTime: predictedDate,
            predictedDuration: averageDuration,
            confidence: confidence
        )
    }
    
    /// 預測下一次餵食時間
    /// - Parameter feedingRecords: 餵食記錄
    /// - Returns: 餵食預測列表
    private func predictNextFeedingTimes(_ feedingRecords: [FeedingRecord]) -> [PredictionResult.FeedingPrediction] {
        guard !feedingRecords.isEmpty else { return [] }
        
        // 按開始時間排序
        let sortedRecords = feedingRecords.sorted { $0.startTime < $1.startTime }
        
        // 按類型分組
        var recordsByType: [FeedingType: [FeedingRecord]] = [:]
        for record in sortedRecords {
            recordsByType[record.type, default: []].append(record)
        }
        
        var predictions: [PredictionResult.FeedingPrediction] = []
        
        // 為每種類型預測下一次餵食時間
        for (type, records) in recordsByType {
            if records.count >= 3 {
                let prediction = predictNextFeedingTime(records, type: type)
                predictions.append(prediction)
            }
        }
        
        return predictions
    }
    
    /// 預測下一次餵食時間
    /// - Parameters:
    ///   - records: 餵食記錄
    ///   - type: 餵食類型
    /// - Returns: 餵食預測
    private func predictNextFeedingTime(_ records: [FeedingRecord], type: FeedingType) -> PredictionResult.FeedingPrediction {
        // 計算平均間隔時間
        var totalInterval: TimeInterval = 0
        for i in 1..<records.count {
            totalInterval += records[i].startTime.timeIntervalSince(records[i-1].startTime)
        }
        let averageInterval = totalInterval / Double(records.count - 1)
        
        // 預測下一次餵食時間
        let lastRecord = records.last!
        let predictedTime = lastRecord.startTime.addingTimeInterval(averageInterval)
        
        // 如果預測時間已過，則基於當前時間預測
        let now = Date()
        let finalPredictedTime = predictedTime < now ? now.addingTimeInterval(averageInterval) : predictedTime
        
        return PredictionResult.FeedingPrediction(
            predictedTime: finalPredictedTime,
            predictedType: type.rawValue,
            confidence: 0.7
        )
    }
    
    /// 計算置信度分數
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    /// - Returns: 置信度分數（0-100）
    private func calculateConfidenceScore(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity]
    ) -> Int {
        var score = 50 // 基礎分數
        
        // 根據數據量調整分數
        if sleepRecords.count > 10 {
            score += 10
        } else if sleepRecords.count > 5 {
            score += 5
        }
        
        if feedingRecords.count > 10 {
            score += 10
        } else if feedingRecords.count > 5 {
            score += 5
        }
        
        if activities.count > 10 {
            score += 5
        }
        
        // 根據數據規律性調整分數
        let calendar = Calendar.current
        let sleepHourComponents = sleepRecords.map { calendar.component(.hour, from: $0.startTime) }
        let sleepHourVariance = calculateVariance(sleepHourComponents)
        
        if sleepHourVariance < 2.0 {
            score += 15
        } else if sleepHourVariance > 4.0 {
            score -= 10
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
