// AIEngine.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：本地AI分析與Deepseek API整合
// 混合AI引擎 - 協調本地和雲端分析

import Foundation

/// 負責協調本地和雲端AI分析，提供統一的分析接口
class AIEngine {
    // MARK: - 單例模式
    static let shared = AIEngine()
    
    // MARK: - 依賴
    private let sleepPatternAnalyzer = SleepPatternAnalyzer()
    private let routineAnalyzer = RoutineAnalyzer()
    private let predictionEngine = PredictionEngine(
        sleepRepository: SleepRecordRepository.shared,
        feedingRepository: FeedingRepository.shared,
        activityRepository: ActivityRepository.shared,
        sleepPatternAnalyzer: SleepPatternAnalyzer(),
        routineAnalyzer: RoutineAnalyzer()
    )
    private let cloudAIService = CloudAIService.shared
    private let networkMonitor = NetworkMonitor.shared
    private let userSettings = UserSettings.shared
    
    // MARK: - 初始化
    private init() {}
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeSleepPattern(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) async -> Result<SleepPatternResult, Error> {
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() {
            // 嘗試使用雲端分析
            let cloudResult = await cloudAIService.analyzeSleepPatternCloud(
                babyId: babyId,
                dateRange: dateRange
            )
            
            // 如果雲端分析成功，返回結果
            if case .success = cloudResult {
                return cloudResult
            }
            
            // 如果雲端分析失敗（非禁用原因），記錄錯誤
            if case .failure(let error) = cloudResult, !(error is CloudError) {
                print("雲端睡眠分析失敗：\(error.localizedDescription)，降級到本地分析")
            }
        }
        
        // 降級到本地分析
        return await sleepPatternAnalyzer.analyzeSleepPattern(
            babyId: babyId,
            dateRange: dateRange
        )
    }
    
    /// 分析作息模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果或錯誤
    func analyzeRoutine(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) async -> Result<RoutineAnalysisResult, Error> {
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() {
            // 嘗試使用雲端分析
            let cloudResult = await cloudAIService.analyzeRoutineCloud(
                babyId: babyId,
                dateRange: dateRange
            )
            
            // 如果雲端分析成功，返回結果
            if case .success = cloudResult {
                return cloudResult
            }
            
            // 如果雲端分析失敗（非禁用原因），記錄錯誤
            if case .failure(let error) = cloudResult, !(error is CloudError) {
                print("雲端作息分析失敗：\(error.localizedDescription)，降級到本地分析")
            }
        }
        
        // 降級到本地分析
        return await routineAnalyzer.analyzeRoutine(
            babyId: babyId,
            dateRange: dateRange
        )
    }
    
    /// 預測下次睡眠
    /// - Parameter babyId: 寶寶ID
    /// - Returns: 預測結果或錯誤
    func predictNextSleep(babyId: String) async -> Result<PredictionResult, Error> {
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() {
            // 嘗試使用雲端分析
            let cloudResult = await cloudAIService.predictNextSleepCloud(babyId: babyId)
            
            // 如果雲端分析成功，返回結果
            if case .success = cloudResult {
                return cloudResult
            }
            
            // 如果雲端分析失敗（非禁用原因），記錄錯誤
            if case .failure(let error) = cloudResult, !(error is CloudError) {
                print("雲端睡眠預測失敗：\(error.localizedDescription)，降級到本地分析")
            }
        }
        
        // 降級到本地分析
        return await predictionEngine.predictNextSleep(babyId: babyId)
    }
    
    /// 獲取分析來源描述
    /// - Parameter isCloudAnalysis: 是否為雲端分析
    /// - Returns: 分析來源描述
    func getAnalysisSourceDescription(isCloudAnalysis: Bool) -> String {
        return isCloudAnalysis ? 
            NSLocalizedString("由Deepseek AI雲端分析提供", comment: "") : 
            NSLocalizedString("由本地分析提供", comment: "")
    }
}
