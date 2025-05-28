import Foundation
import UIKit

/// 首頁視圖模型
class HomeViewModel {
    // MARK: - 屬性
    
    /// 選中的寶寶
    var selectedBaby: Baby?
    
    /// 寶寶年齡描述
    var babyAgeDescription: String = ""
    
    /// 最近活動
    var recentActivities: [ActivityRecord] = []
    
    /// 快速操作
    var quickActions: [QuickAction] = []
    
    /// 總睡眠時間（格式化）
    var totalSleepTimeFormatted: String = "0小時0分鐘"
    
    /// 餵食次數
    var feedingCount: Int = 0
    
    /// 尿布次數
    var diaperCount: Int = 0
    
    /// 活動次數
    var activityCount: Int = 0
    
    /// AI分析
    var aiAnalysis: String?
    
    /// 數據加載完成處理器
    var onDataLoaded: (() -> Void)?
    
    /// 錯誤處理器
    var onError: ((Error) -> Void)?
    
    /// 寶寶倉庫
    private let babyRepository: BabyRepository
    
    /// 活動倉庫
    private let activityRepository: ActivityRepository
    
    /// 睡眠倉庫
    private let sleepRepository: SleepRecordRepository
    
    /// 餵食倉庫
    private let feedingRepository: FeedingRepository
    
    /// AI引擎
    private let aiEngine: AIEngine
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    /// 網絡監視器
    private let networkMonitor: NetworkMonitor
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - babyRepository: 寶寶倉庫
    ///   - activityRepository: 活動倉庫
    ///   - sleepRepository: 睡眠倉庫
    ///   - feedingRepository: 餵食倉庫
    ///   - aiEngine: AI引擎
    ///   - userSettings: 用戶設置
    ///   - networkMonitor: 網絡監視器
    init(babyRepository: BabyRepository = DependencyContainer.shared.resolve(BabyRepository.self)!,
         activityRepository: ActivityRepository = DependencyContainer.shared.resolve(ActivityRepository.self)!,
         sleepRepository: SleepRecordRepository = DependencyContainer.shared.resolve(SleepRecordRepository.self)!,
         feedingRepository: FeedingRepository = DependencyContainer.shared.resolve(FeedingRepository.self)!,
         aiEngine: AIEngine = DependencyContainer.shared.resolve(AIEngine.self)!,
         userSettings: UserSettings = DependencyContainer.shared.resolve(UserSettings.self)!,
         networkMonitor: NetworkMonitor = DependencyContainer.shared.resolve(NetworkMonitor.self)!) {
        self.babyRepository = babyRepository
        self.activityRepository = activityRepository
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
        self.aiEngine = aiEngine
        self.userSettings = userSettings
        self.networkMonitor = networkMonitor
        
        // 設置快速操作
        setupQuickActions()
    }
    
    // MARK: - 公共方法
    
    /// 加載數據
    func loadData() {
        // 獲取選中的寶寶ID
        guard let babyId = userSettings.selectedBabyId else {
            // 處理錯誤
            onError?(RepositoryError.invalidData)
            return
        }
        
        // 獲取寶寶信息
        babyRepository.getBaby(id: babyId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let baby):
                // 設置寶寶
                self.selectedBaby = baby
                
                // 計算寶寶年齡
                self.calculateBabyAge(baby: baby)
                
                // 加載活動數據
                self.loadActivities(babyId: babyId)
                
            case .failure(let error):
                // 處理錯誤
                self.onError?(error)
            }
        }
    }
    
    /// 格式化時間
    /// - Parameter date: 日期
    /// - Returns: 格式化的時間字符串
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - 私有方法
    
    /// 設置快速操作
    private func setupQuickActions() {
        // 添加快速操作
        quickActions = [
            QuickAction(title: "睡眠", icon: UIImage(systemName: "bed.double.fill")!) { [weak self] in
                self?.addSleepRecord()
            },
            QuickAction(title: "餵食", icon: UIImage(systemName: "drop.fill")!) { [weak self] in
                self?.addFeedingRecord()
            },
            QuickAction(title: "尿布", icon: UIImage(systemName: "heart.fill")!) { [weak self] in
                self?.addDiaperRecord()
            },
            QuickAction(title: "其他", icon: UIImage(systemName: "star.fill")!) { [weak self] in
                self?.addActivityRecord()
            }
        ]
    }
    
    /// 計算寶寶年齡
    /// - Parameter baby: 寶寶
    private func calculateBabyAge(baby: Baby) {
        // 獲取當前日期
        let now = Date()
        
        // 計算年齡
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month, .day], from: baby.birthDate, to: now)
        
        // 格式化年齡
        if let years = ageComponents.year, let months = ageComponents.month {
            if years > 0 {
                babyAgeDescription = "\(years)歲\(months)個月"
            } else {
                babyAgeDescription = "\(months)個月"
            }
        } else {
            babyAgeDescription = "未知"
        }
    }
    
    /// 加載活動數據
    /// - Parameter babyId: 寶寶ID
    private func loadActivities(babyId: String) {
        // 獲取今天的開始和結束時間
        let calendar = Calendar.current
        let now = Date()
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
            // 處理錯誤
            onError?(RepositoryError.invalidData)
            return
        }
        
        // 創建調度組
        let dispatchGroup = DispatchGroup()
        
        // 加載活動記錄
        dispatchGroup.enter()
        activityRepository.getActivities(babyId: babyId, startTime: startOfDay, endTime: endOfDay) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let activities):
                // 設置活動記錄
                self.recentActivities = activities
                
                // 計算尿布次數
                self.diaperCount = activities.filter { $0.type == .diaper }.count
                
                // 計算活動次數
                self.activityCount = activities.count
                
            case .failure(let error):
                // 處理錯誤
                self.onError?(error)
            }
            
            dispatchGroup.leave()
        }
        
        // 加載睡眠記錄
        dispatchGroup.enter()
        sleepRepository.getSleepRecords(babyId: babyId, startTime: startOfDay, endTime: endOfDay) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let sleepRecords):
                // 計算總睡眠時間
                let totalSleepTime = sleepRecords.reduce(0) { $0 + $1.duration }
                
                // 格式化總睡眠時間
                let hours = Int(totalSleepTime / 3600)
                let minutes = Int((totalSleepTime.truncatingRemainder(dividingBy: 3600)) / 60)
                self.totalSleepTimeFormatted = "\(hours)小時\(minutes)分鐘"
                
                // 添加到最近活動
                for sleepRecord in sleepRecords {
                    let activity = ActivityRecord(
                        id: sleepRecord.id,
                        babyId: sleepRecord.babyId,
                        type: .sleep,
                        name: "睡眠",
                        startTime: sleepRecord.startTime,
                        endTime: sleepRecord.endTime,
                        duration: sleepRecord.duration,
                        notes: sleepRecord.notes
                    )
                    self.recentActivities.append(activity)
                }
                
            case .failure(let error):
                // 處理錯誤
                self.onError?(error)
            }
            
            dispatchGroup.leave()
        }
        
        // 加載餵食記錄
        dispatchGroup.enter()
        feedingRepository.getFeedingRecords(babyId: babyId, startTime: startOfDay, endTime: endOfDay) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let feedingRecords):
                // 計算餵食次數
                self.feedingCount = feedingRecords.count
                
                // 添加到最近活動
                for feedingRecord in feedingRecords {
                    let activity = ActivityRecord(
                        id: feedingRecord.id,
                        babyId: feedingRecord.babyId,
                        type: .feeding,
                        name: "餵食",
                        startTime: feedingRecord.startTime,
                        endTime: feedingRecord.endTime,
                        duration: feedingRecord.duration,
                        notes: feedingRecord.notes
                    )
                    self.recentActivities.append(activity)
                }
                
            case .failure(let error):
                // 處理錯誤
                self.onError?(error)
            }
            
            dispatchGroup.leave()
        }
        
        // 所有數據加載完成
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // 排序最近活動
            self.recentActivities.sort { $0.startTime > $1.startTime }
            
            // 限制最近活動數量
            if self.recentActivities.count > 5 {
                self.recentActivities = Array(self.recentActivities.prefix(5))
            }
            
            // 生成AI分析
            self.generateAIAnalysis(babyId: babyId)
            
            // 通知數據加載完成
            self.onDataLoaded?()
        }
    }
    
    /// 生成AI分析
    /// - Parameter babyId: 寶寶ID
    private func generateAIAnalysis(babyId: String) {
        // 檢查網絡連接
        if networkMonitor.isConnected {
            // 檢查用戶設置
            if userSettings.isCloudAnalysisEnabled {
                // 生成AI分析
                aiEngine.generateDailySummary(babyId: babyId) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let analysis):
                        // 設置AI分析
                        self.aiAnalysis = analysis
                        
                        // 通知數據加載完成
                        self.onDataLoaded?()
                        
                    case .failure:
                        // 使用本地分析
                        self.generateLocalAnalysis(babyId: babyId)
                    }
                }
            } else {
                // 使用本地分析
                generateLocalAnalysis(babyId: babyId)
            }
        } else {
            // 使用本地分析
            generateLocalAnalysis(babyId: babyId)
        }
    }
    
    /// 生成本地分析
    /// - Parameter babyId: 寶寶ID
    private func generateLocalAnalysis(babyId: String) {
        // 生成本地分析
        aiEngine.generateLocalDailySummary(babyId: babyId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let analysis):
                // 設置AI分析
                self.aiAnalysis = analysis
                
            case .failure:
                // 清空AI分析
                self.aiAnalysis = nil
            }
            
            // 通知數據加載完成
            self.onDataLoaded?()
        }
    }
    
    /// 添加睡眠記錄
    private func addSleepRecord() {
        // 創建視圖控制器
        let viewController = SleepRecordViewController()
        
        // 獲取當前視圖控制器
        if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
            // 顯示視圖控制器
            topViewController.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    /// 添加餵食記錄
    private func addFeedingRecord() {
        // 創建視圖控制器
        let viewController = FeedingRecordViewController()
        
        // 獲取當前視圖控制器
        if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
            // 顯示視圖控制器
            topViewController.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    /// 添加尿布記錄
    private func addDiaperRecord() {
        // 創建視圖模型
        let viewModel = ActivityRecordViewModel()
        viewModel.activityType = .diaper
        
        // 創建視圖控制器
        let viewController = ActivityRecordViewController(viewModel: viewModel)
        
        // 獲取當前視圖控制器
        if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
            // 顯示視圖控制器
            topViewController.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    /// 添加活動記錄
    private func addActivityRecord() {
        // 創建視圖控制器
        let viewController = ActivityRecordViewController()
        
        // 獲取當前視圖控制器
        if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
            // 顯示視圖控制器
            topViewController.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

/// 快速操作
struct QuickAction {
    /// 標題
    let title: String
    
    /// 圖標
    let icon: UIImage
    
    /// 操作
    let action: () -> Void
}

// MARK: - UIViewController 擴展

extension UIViewController {
    /// 獲取最頂層視圖控制器
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        return self
    }
}
