import Foundation
import Combine

/// 活動分析視圖模型
class ActivityAnalysisViewModel {
    // MARK: - 屬性
    
    /// 活動倉庫
    private let activityRepository: ActivityRepository
    
    /// 作息模式分析器
    private let routineAnalyzer: RoutineAnalyzer
    
    /// 取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 活動列表
    private var activities: [Activity] = []
    
    /// 活動持續時間摘要
    private(set) var activityDurationSummary: String?
    
    /// 活動模式摘要
    private(set) var activityPatternSummary: String?
    
    /// 數據加載完成回調
    var onDataLoaded: (() -> Void)?
    
    /// 錯誤回調
    var onError: ((Error) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - activityRepository: 活動倉庫
    ///   - routineAnalyzer: 作息模式分析器
    init(activityRepository: ActivityRepository, routineAnalyzer: RoutineAnalyzer) {
        self.activityRepository = activityRepository
        self.routineAnalyzer = routineAnalyzer
    }
    
    // MARK: - 公共方法
    
    /// 加載數據
    /// - Parameters:
    ///   - startDate: 開始日期
    ///   - endDate: 結束日期
    func loadData(from startDate: Date, to endDate: Date) {
        // 创建日期范围
        let dateRange = startDate...endDate
        
        // 获取当前用户选择的宝宝ID
        guard let babyId = UserSettings.shared.selectedBabyId else {
            onError?(RepositoryError.invalidData)
            return
        }
        
        // 调用API获取活动记录
        activityRepository.getActivities(babyId: babyId, dateRange: dateRange) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let activities):
                self.activities = activities
                
                // 计算活动持续时间统计
                self.calculateActivityDurationSummary()
                
                // 如果没有活动记录，直接返回
                if activities.isEmpty {
                    self.activityPatternSummary = "沒有足夠的活動記錄進行分析"
                    self.onDataLoaded?()
                    return
                }
                
                // 分析活动模式
                self.routineAnalyzer.analyzeActivityPattern(activities: activities) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let analysis):
                        // 设置活动模式摘要
                        self.activityPatternSummary = analysis.summary
                        self.onDataLoaded?()
                        
                    case .failure(let error):
                        self.onError?(error)
                    }
                }
                
            case .failure(let error):
                self.onError?(error)
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 計算活動持續時間統計
    private func calculateActivityDurationSummary() {
        if activities.isEmpty {
            activityDurationSummary = "沒有活動記錄"
            return
        }
        
        // 按類型分組
        var activitiesByType: [ActivityType: [Activity]] = [:]
        for activity in activities {
            activitiesByType[activity.type, default: []].append(activity)
        }
        
        // 計算每種類型的平均持續時間
        var summaryLines: [String] = []
        
        for (type, typeActivities) in activitiesByType {
            let validActivities = typeActivities.filter { $0.duration != nil }
            if !validActivities.isEmpty {
                let totalDuration = validActivities.compactMap { $0.duration }.reduce(0, +)
                let averageDuration = totalDuration / Double(validActivities.count)
                
                let hours = Int(averageDuration / 3600)
                let minutes = Int((averageDuration.truncatingRemainder(dividingBy: 3600)) / 60)
                
                if hours > 0 {
                    summaryLines.append("\(type.rawValue): 平均 \(hours)小時 \(minutes)分鐘")
                } else {
                    summaryLines.append("\(type.rawValue): 平均 \(minutes)分鐘")
                }
            }
        }
        
        // 計算總體平均持續時間
        let validActivities = activities.filter { $0.duration != nil }
        if !validActivities.isEmpty {
            let totalDuration = validActivities.compactMap { $0.duration }.reduce(0, +)
            let averageDuration = totalDuration / Double(validActivities.count)
            
            let hours = Int(averageDuration / 3600)
            let minutes = Int((averageDuration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if hours > 0 {
                summaryLines.append("總體平均: \(hours)小時 \(minutes)分鐘")
            } else {
                summaryLines.append("總體平均: \(minutes)分鐘")
            }
        }
        
        activityDurationSummary = summaryLines.joined(separator: "\n")
    }
}
