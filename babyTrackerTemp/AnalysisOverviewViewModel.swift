import Foundation
import Combine

/// 分析總覽視圖模型
class AnalysisOverviewViewModel {
    // MARK: - 屬性
    
    /// 睡眠記錄倉庫
    private let sleepRecordRepository: SleepRecordRepository
    
    /// 餵食記錄倉庫
    private let feedingRepository: FeedingRepository
    
    /// 活動倉庫
    private let activityRepository: ActivityRepository
    
    /// 成長記錄倉庫
    private let growthRepository: GrowthRepository
    
    /// 睡眠模式分析器
    private let sleepPatternAnalyzer: SleepPatternAnalyzer
    
    /// 作息模式分析器
    private let routineAnalyzer: RoutineAnalyzer
    
    /// 取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 睡眠分析摘要
    private(set) var sleepAnalysisSummary: String?
    
    /// 餵食分析摘要
    private(set) var feedingAnalysisSummary: String?
    
    /// 活動分析摘要
    private(set) var activityAnalysisSummary: String?
    
    /// 成長分析摘要
    private(set) var growthAnalysisSummary: String?
    
    /// 數據加載完成回調
    var onDataLoaded: (() -> Void)?
    
    /// 錯誤回調
    var onError: ((Error) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - sleepRecordRepository: 睡眠記錄倉庫
    ///   - feedingRepository: 餵食記錄倉庫
    ///   - activityRepository: 活動倉庫
    ///   - growthRepository: 成長記錄倉庫
    ///   - sleepPatternAnalyzer: 睡眠模式分析器
    ///   - routineAnalyzer: 作息模式分析器
    init(
        sleepRecordRepository: SleepRecordRepository,
        feedingRepository: FeedingRepository,
        activityRepository: ActivityRepository,
        growthRepository: GrowthRepository,
        sleepPatternAnalyzer: SleepPatternAnalyzer,
        routineAnalyzer: RoutineAnalyzer
    ) {
        self.sleepRecordRepository = sleepRecordRepository
        self.feedingRepository = feedingRepository
        self.activityRepository = activityRepository
        self.growthRepository = growthRepository
        self.sleepPatternAnalyzer = sleepPatternAnalyzer
        self.routineAnalyzer = routineAnalyzer
    }
    
    // MARK: - 公共方法
    
    /// 加載數據
    func loadData() {
        // 獲取過去7天的數據
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        // 創建一個組合發布者，等待所有數據加載完成
        Publishers.Zip4(
            loadSleepData(from: startDate, to: endDate),
            loadFeedingData(from: startDate, to: endDate),
            loadActivityData(from: startDate, to: endDate),
            loadGrowthData(from: startDate, to: endDate)
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.onError?(error)
                }
            },
            receiveValue: { [weak self] _ in
                self?.onDataLoaded?()
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - 私有方法
    
    /// 加載睡眠數據
    /// - Parameters:
    ///   - startDate: 開始日期
    ///   - endDate: 結束日期
    /// - Returns: 發布者
    private func loadSleepData(from startDate: Date, to endDate: Date) -> AnyPublisher<Void, Error> {
        return sleepRecordRepository.getSleepRecords(from: startDate, to: endDate)
            .flatMap { [weak self] sleepRecords -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: AnalysisError.analyzerNotAvailable).eraseToAnyPublisher()
                }
                
                if sleepRecords.isEmpty {
                    self.sleepAnalysisSummary = "過去7天沒有睡眠記錄"
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                
                return self.sleepPatternAnalyzer.analyzeSleepPattern(sleepRecords: sleepRecords)
                    .map { analysis in
                        // 計算平均睡眠時間
                        let totalSleepTime = sleepRecords.compactMap { $0.duration }.reduce(0, +)
                        let averageSleepTime = totalSleepTime / Double(sleepRecords.count)
                        let hours = Int(averageSleepTime / 3600)
                        let minutes = Int((averageSleepTime.truncatingRemainder(dividingBy: 3600)) / 60)
                        
                        // 設置睡眠分析摘要
                        self.sleepAnalysisSummary = "平均睡眠時間: \(hours)小時\(minutes)分鐘，品質: \(analysis.quality.rawValue)"
                        
                        return ()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// 加載餵食數據
    /// - Parameters:
    ///   - startDate: 開始日期
    ///   - endDate: 結束日期
    /// - Returns: 發布者
    private func loadFeedingData(from startDate: Date, to endDate: Date) -> AnyPublisher<Void, Error> {
        return feedingRepository.getFeedingRecords(from: startDate, to: endDate)
            .map { [weak self] feedingRecords in
                guard let self = self else { return }
                
                if feedingRecords.isEmpty {
                    self.feedingAnalysisSummary = "過去7天沒有餵食記錄"
                    return
                }
                
                // 計算餵食次數
                let feedingCount = feedingRecords.count
                
                // 計算平均餵食間隔
                let sortedRecords = feedingRecords.sorted { $0.startTime < $1.startTime }
                var totalInterval: TimeInterval = 0
                var intervalCount = 0
                
                for i in 1..<sortedRecords.count {
                    let interval = sortedRecords[i].startTime.timeIntervalSince(sortedRecords[i-1].startTime)
                    if interval < 24 * 3600 { // 只計算24小時內的間隔
                        totalInterval += interval
                        intervalCount += 1
                    }
                }
                
                let averageInterval = intervalCount > 0 ? totalInterval / Double(intervalCount) : 0
                let hours = Int(averageInterval / 3600)
                let minutes = Int((averageInterval.truncatingRemainder(dividingBy: 3600)) / 60)
                
                // 設置餵食分析摘要
                self.feedingAnalysisSummary = "7天內餵食\(feedingCount)次，平均間隔\(hours)小時\(minutes)分鐘"
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    /// 加載活動數據
    /// - Parameters:
    ///   - startDate: 開始日期
    ///   - endDate: 結束日期
    /// - Returns: 發布者
    private func loadActivityData(from startDate: Date, to endDate: Date) -> AnyPublisher<Void, Error> {
        return activityRepository.getActivities(from: startDate, to: endDate)
            .map { [weak self] activities in
                guard let self = self else { return }
                
                if activities.isEmpty {
                    self.activityAnalysisSummary = "過去7天沒有活動記錄"
                    return
                }
                
                // 按類型分組
                var activityCounts: [ActivityType: Int] = [:]
                for activity in activities {
                    activityCounts[activity.type, default: 0] += 1
                }
                
                // 找出最常見的活動類型
                if let mostCommonActivity = activityCounts.max(by: { $0.value < $1.value }) {
                    self.activityAnalysisSummary = "7天內記錄了\(activities.count)個活動，最常見: \(mostCommonActivity.key.rawValue)"
                } else {
                    self.activityAnalysisSummary = "7天內記錄了\(activities.count)個活動"
                }
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    /// 加載成長數據
    /// - Parameters:
    ///   - startDate: 開始日期
    ///   - endDate: 結束日期
    /// - Returns: 發布者
    private func loadGrowthData(from startDate: Date, to endDate: Date) -> AnyPublisher<Void, Error> {
        return growthRepository.getGrowthRecords(from: startDate, to: endDate)
            .map { [weak self] growthRecords in
                guard let self = self else { return }
                
                if growthRecords.isEmpty {
                    self.growthAnalysisSummary = "過去7天沒有成長記錄"
                    return
                }
                
                // 獲取最新的成長記錄
                if let latestRecord = growthRecords.max(by: { $0.date < $1.date }) {
                    self.growthAnalysisSummary = "最新記錄: 身高\(latestRecord.height)cm，體重\(latestRecord.weight)kg"
                } else {
                    self.growthAnalysisSummary = "7天內有\(growthRecords.count)條成長記錄"
                }
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
