import Foundation

/// AI引擎 - 混合模式（本地+雲端）
class AIEngine {
    // MARK: - 單例模式
    static let shared = AIEngine()
    
    private init() {}
    
    // MARK: - 依賴
    private let sleepPatternAnalyzer = DependencyContainer.shared.sleepPatternAnalyzer
    private let routineAnalyzer = DependencyContainer.shared.routineAnalyzer
    private let predictionEngine = DependencyContainer.shared.predictionEngine
    private let cloudAIService = DependencyContainer.shared.cloudAIService
    private let networkMonitor = DependencyContainer.shared.networkMonitor
    private let userSettings = DependencyContainer.shared.userSettings
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    ///   - completion: 完成回調
    func analyzeSleepPattern(
        babyId: String,
        dateRange: ClosedRange<Date>,
        completion: @escaping (Result<SleepPatternResult, Error>) -> Void
    ) {
        Task {
            let result = await analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// 分析睡眠模式（異步）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeSleepPattern(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) async -> Result<SleepPatternResult, Error> {
        // 獲取睡眠記錄
        let sleepRepository = DependencyContainer.shared.sleepRepository
        let recordsResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
        
        switch recordsResult {
        case .success(let records):
            // 檢查數據是否足夠
            guard !records.isEmpty else {
                return .failure(AnalysisError.insufficientData)
            }
            
            // 檢查是否可以使用雲端分析
            if networkMonitor.canUseCloudAnalysis() && userSettings.isCloudAnalysisEnabled {
                // 嘗試使用雲端分析
                let cloudResult = await cloudAIService.analyzeSleepPattern(sleepRecords: records)
                
                switch cloudResult {
                case .success(let result):
                    return .success(result)
                case .failure(let error):
                    // 如果雲端分析失敗，回退到本地分析
                    print("雲端分析失敗: \(error.localizedDescription)，回退到本地分析")
                    return await sleepPatternAnalyzer.analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
                }
            } else {
                // 使用本地分析
                return await sleepPatternAnalyzer.analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// 分析作息規律
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    ///   - completion: 完成回調
    func analyzeRoutine(
        babyId: String,
        dateRange: ClosedRange<Date>,
        completion: @escaping (Result<RoutineAnalysisResult, Error>) -> Void
    ) {
        Task {
            let result = await analyzeRoutine(babyId: babyId, dateRange: dateRange)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// 分析作息規律（異步）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeRoutine(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) async -> Result<RoutineAnalysisResult, Error> {
        // 獲取睡眠記錄
        let sleepRepository = DependencyContainer.shared.sleepRepository
        let sleepResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
        
        // 獲取餵食記錄
        let feedingRepository = DependencyContainer.shared.feedingRepository
        let feedingResult = await feedingRepository.getFeedingRecords(babyId: babyId, dateRange: dateRange)
        
        // 獲取活動記錄
        let activityRepository = DependencyContainer.shared.activityRepository
        let activityResult = await activityRepository.getActivities(babyId: babyId, dateRange: dateRange)
        
        // 檢查是否有任何錯誤
        if case .failure(let error) = sleepResult {
            return .failure(error)
        }
        
        if case .failure(let error) = feedingResult {
            return .failure(error)
        }
        
        if case .failure(let error) = activityResult {
            return .failure(error)
        }
        
        // 提取記錄
        guard case .success(let sleepRecords) = sleepResult,
              case .success(let feedingRecords) = feedingResult,
              case .success(let activities) = activityResult else {
            return .failure(AnalysisError.processingError)
        }
        
        // 檢查數據是否足夠
        if sleepRecords.isEmpty && feedingRecords.isEmpty && activities.isEmpty {
            return .failure(AnalysisError.insufficientData)
        }
        
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() && userSettings.isCloudAnalysisEnabled {
            // 嘗試使用雲端分析
            let cloudResult = await cloudAIService.analyzeRoutine(
                sleepRecords: sleepRecords,
                feedingRecords: feedingRecords,
                activities: activities
            )
            
            switch cloudResult {
            case .success(let result):
                return .success(result)
            case .failure(let error):
                // 如果雲端分析失敗，回退到本地分析
                print("雲端分析失敗: \(error.localizedDescription)，回退到本地分析")
                return await routineAnalyzer.analyzeRoutine(babyId: babyId, dateRange: dateRange)
            }
        } else {
            // 使用本地分析
            return await routineAnalyzer.analyzeRoutine(babyId: babyId, dateRange: dateRange)
        }
    }
    
    /// 預測下一次睡眠
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 用於分析的日期範圍
    ///   - completion: 完成回調
    func predictNextSleep(
        babyId: String,
        dateRange: ClosedRange<Date>,
        completion: @escaping (Result<PredictionResult, Error>) -> Void
    ) {
        Task {
            let result = await predictNextSleep(babyId: babyId, dateRange: dateRange)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// 預測下一次睡眠（異步）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 用於分析的日期範圍
    /// - Returns: 預測結果或錯誤
    func predictNextSleep(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) async -> Result<PredictionResult, Error> {
        // 獲取睡眠記錄
        let sleepRepository = DependencyContainer.shared.sleepRepository
        let sleepResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
        
        // 獲取餵食記錄
        let feedingRepository = DependencyContainer.shared.feedingRepository
        let feedingResult = await feedingRepository.getFeedingRecords(babyId: babyId, dateRange: dateRange)
        
        // 獲取活動記錄
        let activityRepository = DependencyContainer.shared.activityRepository
        let activityResult = await activityRepository.getActivities(babyId: babyId, dateRange: dateRange)
        
        // 檢查是否有任何錯誤
        if case .failure(let error) = sleepResult {
            return .failure(error)
        }
        
        if case .failure(let error) = feedingResult {
            return .failure(error)
        }
        
        if case .failure(let error) = activityResult {
            return .failure(error)
        }
        
        // 提取記錄
        guard case .success(let sleepRecords) = sleepResult,
              case .success(let feedingRecords) = feedingResult,
              case .success(let activities) = activityResult else {
            return .failure(AnalysisError.processingError)
        }
        
        // 檢查數據是否足夠
        if sleepRecords.isEmpty {
            return .failure(AnalysisError.insufficientData)
        }
        
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() && userSettings.isCloudAnalysisEnabled {
            // 嘗試使用雲端分析
            let cloudResult = await cloudAIService.predictNextSleep(
                sleepRecords: sleepRecords,
                feedingRecords: feedingRecords,
                activities: activities
            )
            
            switch cloudResult {
            case .success(let result):
                return .success(result)
            case .failure(let error):
                // 如果雲端分析失敗，回退到本地分析
                print("雲端分析失敗: \(error.localizedDescription)，回退到本地分析")
                return await predictionEngine.predictNextSleep(babyId: babyId, dateRange: dateRange)
            }
        } else {
            // 使用本地分析
            return await predictionEngine.predictNextSleep(babyId: babyId, dateRange: dateRange)
        }
    }
    
    /// 檢查是否可以使用雲端分析
    /// - Returns: 是否可以使用雲端分析
    func canUseCloudAnalysis() -> Bool {
        return networkMonitor.canUseCloudAnalysis() && userSettings.isCloudAnalysisEnabled
    }
    
    /// 獲取當前網絡狀態
    /// - Returns: 網絡狀態描述
    func getNetworkStatus() -> String {
        if !networkMonitor.isConnected {
            return "離線模式"
        } else if networkMonitor.isWiFi {
            return "WiFi連接"
        } else if networkMonitor.isCellular {
            return "蜂窩數據連接"
        } else {
            return "已連接"
        }
    }
}
