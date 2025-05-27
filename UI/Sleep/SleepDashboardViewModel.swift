import Foundation

/// 睡眠儀表板視圖模型
class SleepDashboardViewModel {
    // MARK: - 屬性
    
    /// 平均睡眠時間（秒）
    var averageSleepDuration: TimeInterval?
    
    /// 睡眠質量
    var sleepQuality: String?
    
    /// 睡眠模式
    var sleepPattern: String?
    
    /// 分析結果
    var analysis: String?
    
    /// 睡眠數據
    var sleepData: [SleepRecord]?
    
    /// 數據加載完成處理器
    var onDataLoaded: (() -> Void)?
    
    /// 分析完成處理器
    var onAnalysisCompleted: ((Result<String, Error>) -> Void)?
    
    /// 睡眠記錄倉庫
    private let sleepRepository: SleepRecordRepository
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    /// 網絡監視器
    private let networkMonitor: NetworkMonitor
    
    /// AI引擎
    private let aiEngine: AIEngine
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - sleepRepository: 睡眠記錄倉庫
    ///   - userSettings: 用戶設置
    ///   - networkMonitor: 網絡監視器
    ///   - aiEngine: AI引擎
    init(sleepRepository: SleepRecordRepository = DependencyContainer.shared.resolve(SleepRecordRepository.self)!,
         userSettings: UserSettings = DependencyContainer.shared.resolve(UserSettings.self)!,
         networkMonitor: NetworkMonitor = DependencyContainer.shared.resolve(NetworkMonitor.self)!,
         aiEngine: AIEngine = DependencyContainer.shared.resolve(AIEngine.self)!) {
        self.sleepRepository = sleepRepository
        self.userSettings = userSettings
        self.networkMonitor = networkMonitor
        self.aiEngine = aiEngine
    }
    
    // MARK: - 公共方法
    
    /// 加載數據
    func loadData() {
        // 獲取選中的寶寶ID
        guard let babyId = userSettings.selectedBabyId else {
            // 通知數據加載完成
            onDataLoaded?()
            return
        }
        
        // 獲取過去30天的日期範圍
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        // 獲取睡眠記錄
        sleepRepository.getSleepRecords(forBabyId: babyId, startDate: startDate, endDate: endDate) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let records):
                // 保存睡眠數據
                self.sleepData = records
                
                // 計算平均睡眠時間
                if !records.isEmpty {
                    let totalDuration = records.reduce(0) { $0 + $1.duration }
                    self.averageSleepDuration = totalDuration / Double(records.count)
                } else {
                    self.averageSleepDuration = nil
                }
                
                // 計算睡眠質量
                self.calculateSleepQuality(records: records)
                
                // 識別睡眠模式
                self.identifySleepPattern(records: records)
                
                // 通知數據加載完成
                self.onDataLoaded?()
                
            case .failure:
                // 清除數據
                self.sleepData = nil
                self.averageSleepDuration = nil
                self.sleepQuality = nil
                self.sleepPattern = nil
                
                // 通知數據加載完成
                self.onDataLoaded?()
            }
        }
    }
    
    /// 執行深度分析
    func performDeepAnalysis() {
        // 檢查網絡連接
        guard networkMonitor.isConnected else {
            // 通知分析完成（失敗）
            onAnalysisCompleted?(.failure(NetworkError.noConnection))
            return
        }
        
        // 檢查是否有睡眠數據
        guard let sleepData = sleepData, !sleepData.isEmpty else {
            // 通知分析完成（失敗）
            onAnalysisCompleted?(.failure(AnalysisError.insufficientData))
            return
        }
        
        // 檢查用戶設置
        guard userSettings.isCloudAnalysisEnabled else {
            // 通知分析完成（失敗）
            onAnalysisCompleted?(.failure(AnalysisError.cloudAnalysisDisabled))
            return
        }
        
        // 執行深度分析
        aiEngine.analyzeSleepPattern(sleepData: sleepData) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let analysisResult):
                // 保存分析結果
                self.analysis = analysisResult
                
                // 通知分析完成（成功）
                self.onAnalysisCompleted?(.success(analysisResult))
                
            case .failure(let error):
                // 通知分析完成（失敗）
                self.onAnalysisCompleted?(.failure(error))
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 計算睡眠質量
    /// - Parameter records: 睡眠記錄
    private func calculateSleepQuality(records: [SleepRecord]) {
        // 檢查是否有睡眠數據
        guard !records.isEmpty else {
            sleepQuality = nil
            return
        }
        
        // 計算平均睡眠時間
        let totalDuration = records.reduce(0) { $0 + $1.duration }
        let averageDuration = totalDuration / Double(records.count)
        
        // 計算睡眠中斷次數
        let totalInterruptions = records.reduce(0) { $0 + ($1.interruptions?.count ?? 0) }
        let averageInterruptions = Double(totalInterruptions) / Double(records.count)
        
        // 根據平均睡眠時間和中斷次數評估睡眠質量
        if averageDuration >= 3600 * 8 && averageInterruptions < 1 {
            sleepQuality = "優"
        } else if averageDuration >= 3600 * 7 && averageInterruptions < 2 {
            sleepQuality = "良"
        } else if averageDuration >= 3600 * 6 && averageInterruptions < 3 {
            sleepQuality = "中"
        } else {
            sleepQuality = "差"
        }
    }
    
    /// 識別睡眠模式
    /// - Parameter records: 睡眠記錄
    private func identifySleepPattern(records: [SleepRecord]) {
        // 檢查是否有睡眠數據
        guard !records.isEmpty else {
            sleepPattern = nil
            return
        }
        
        // 計算平均睡眠開始時間
        var totalStartSeconds: TimeInterval = 0
        for record in records {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: record.startTime)
            let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
            totalStartSeconds += seconds
        }
        let averageStartSeconds = totalStartSeconds / Double(records.count)
        
        // 將平均開始時間轉換為小時和分鐘
        let averageStartHour = Int(averageStartSeconds / 3600)
        let averageStartMinute = Int((averageStartSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        // 根據平均開始時間識別睡眠模式
        if averageStartHour >= 18 && averageStartHour < 21 {
            sleepPattern = "早睡型"
        } else if averageStartHour >= 21 && averageStartHour < 23 {
            sleepPattern = "正常型"
        } else {
            sleepPattern = "晚睡型"
        }
        
        // 添加平均開始時間
        sleepPattern! += " (平均睡眠時間: \(averageStartHour):\(String(format: "%02d", averageStartMinute)))"
    }
}
