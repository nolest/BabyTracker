import Foundation
import Combine

/// 餵食分析視圖模型
class FeedingAnalysisViewModel {
    // MARK: - 屬性
    
    /// 餵食倉庫
    private let feedingRepository: FeedingRepository
    
    /// AI引擎
    private let aiEngine: AIEngine
    
    /// 網絡監視器
    private let networkMonitor: NetworkMonitor
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    /// 取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 主要餵食類型
    private(set) var dominantFeedingType: String?
    
    /// 平均餵食時間（秒）
    private(set) var averageFeedingDuration: TimeInterval?
    
    /// 平均餵食間隔（秒）
    private(set) var averageFeedingInterval: TimeInterval?
    
    /// 餵食模式
    private(set) var feedingPattern: String?
    
    /// 分析結果
    private(set) var analysis: String?
    
    /// 數據加載完成回調
    var onDataLoaded: (() -> Void)?
    
    /// 分析完成回調
    var onAnalysisCompleted: ((Result<String, Error>) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - feedingRepository: 餵食倉庫
    ///   - aiEngine: AI引擎
    ///   - networkMonitor: 網絡監視器
    ///   - userSettings: 用戶設置
    init(
        feedingRepository: FeedingRepository,
        aiEngine: AIEngine,
        networkMonitor: NetworkMonitor,
        userSettings: UserSettings
    ) {
        self.feedingRepository = feedingRepository
        self.aiEngine = aiEngine
        self.networkMonitor = networkMonitor
        self.userSettings = userSettings
    }
    
    // MARK: - 公共方法
    
    /// 加載數據
    func loadData() {
        // 獲取過去30天的餵食記錄
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        feedingRepository.getFeedingRecords(from: startDate, to: endDate)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Error loading feeding records: \(error)")
                    }
                    
                    // 即使失敗也調用數據加載完成回調
                    self?.onDataLoaded?()
                },
                receiveValue: { [weak self] records in
                    self?.processRecords(records)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 執行深度分析
    func performDeepAnalysis() {
        // 檢查網絡連接
        guard networkMonitor.isConnected else {
            onAnalysisCompleted?(.failure(NetworkError.noConnection))
            return
        }
        
        // 檢查用戶是否啟用雲端分析
        guard userSettings.isCloudAnalysisEnabled else {
            // 使用本地分析
            performLocalAnalysis()
            return
        }
        
        // 獲取過去30天的餵食記錄
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        feedingRepository.getFeedingRecords(from: startDate, to: endDate)
            .flatMap { [weak self] records -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: AnalysisError.unknown).eraseToAnyPublisher()
                }
                
                // 使用AI引擎進行深度分析
                return self.aiEngine.analyzeFeedingPattern(records: records)
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.onAnalysisCompleted?(.failure(error))
                    }
                },
                receiveValue: { [weak self] analysisResult in
                    self?.analysis = analysisResult
                    self?.onAnalysisCompleted?(.success(analysisResult))
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 私有方法
    
    /// 處理餵食記錄
    /// - Parameter records: 餵食記錄
    private func processRecords(_ records: [FeedingRecord]) {
        guard !records.isEmpty else {
            // 沒有記錄，設置默認值
            dominantFeedingType = nil
            averageFeedingDuration = nil
            averageFeedingInterval = nil
            feedingPattern = nil
            
            // 調用數據加載完成回調
            onDataLoaded?()
            return
        }
        
        // 計算主要餵食類型
        let feedingTypes = records.map { $0.type }
        let feedingTypeCounts = Dictionary(grouping: feedingTypes, by: { $0 }).mapValues { $0.count }
        dominantFeedingType = feedingTypeCounts.max(by: { $0.value < $1.value })?.key.rawValue
        
        // 計算平均餵食時間
        let durations = records.compactMap { $0.duration }
        if !durations.isEmpty {
            averageFeedingDuration = durations.reduce(0, +) / Double(durations.count)
        }
        
        // 計算平均餵食間隔
        if records.count > 1 {
            let sortedRecords = records.sorted(by: { $0.startTime < $1.startTime })
            var intervals: [TimeInterval] = []
            
            for i in 0..<(sortedRecords.count - 1) {
                let interval = sortedRecords[i + 1].startTime.timeIntervalSince(sortedRecords[i].startTime)
                intervals.append(interval)
            }
            
            averageFeedingInterval = intervals.reduce(0, +) / Double(intervals.count)
        }
        
        // 確定餵食模式
        determineFeedingPattern(records)
        
        // 調用數據加載完成回調
        onDataLoaded?()
    }
    
    /// 確定餵食模式
    /// - Parameter records: 餵食記錄
    private func determineFeedingPattern(_ records: [FeedingRecord]) {
        guard !records.isEmpty else {
            feedingPattern = nil
            return
        }
        
        // 按日期分組
        let calendar = Calendar.current
        let recordsByDay = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.startTime)
        }
        
        // 計算每天的餵食次數
        let feedingsPerDay = recordsByDay.mapValues { $0.count }
        let averageFeedingsPerDay = Double(records.count) / Double(recordsByDay.count)
        
        // 確定模式
        if averageFeedingsPerDay >= 8 {
            feedingPattern = "頻繁餵食"
        } else if averageFeedingsPerDay >= 6 {
            feedingPattern = "規律餵食"
        } else {
            feedingPattern = "間隔餵食"
        }
    }
    
    /// 執行本地分析
    private func performLocalAnalysis() {
        // 獲取過去30天的餵食記錄
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        feedingRepository.getFeedingRecords(from: startDate, to: endDate)
            .map { [weak self] records -> String in
                guard let self = self else {
                    return "無法進行分析"
                }
                
                // 如果沒有記錄
                guard !records.isEmpty else {
                    return "沒有足夠的餵食記錄進行分析"
                }
                
                // 生成基本分析結果
                var result = "基於過去30天的\(records.count)次餵食記錄："
                
                // 添加主要餵食類型
                if let dominantType = self.dominantFeedingType {
                    result += "\n- 主要餵食類型為\(dominantType)"
                }
                
                // 添加平均餵食時間
                if let duration = self.averageFeedingDuration {
                    let minutes = Int(duration / 60)
                    let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
                    result += "\n- 平均每次餵食時間為\(minutes)分\(seconds)秒"
                }
                
                // 添加平均餵食間隔
                if let interval = self.averageFeedingInterval {
                    let hours = Int(interval / 3600)
                    let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
                    result += "\n- 平均餵食間隔為\(hours)小時\(minutes)分鐘"
                }
                
                // 添加餵食模式
                if let pattern = self.feedingPattern {
                    result += "\n- 餵食模式為\(pattern)"
                }
                
                // 添加建議
                result += "\n\n建議：請確保餵食間隔適當，避免過度餵食或餵食不足。如需更詳細的分析，請啟用雲端分析功能。"
                
                return result
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.onAnalysisCompleted?(.failure(error))
                    }
                },
                receiveValue: { [weak self] analysisResult in
                    self?.analysis = analysisResult
                    self?.onAnalysisCompleted?(.success(analysisResult))
                }
            )
            .store(in: &cancellables)
    }
}
