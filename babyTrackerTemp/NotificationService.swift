import Foundation
import UserNotifications

/// 通知服務
class NotificationService {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = NotificationService()
    
    // MARK: - 屬性
    
    /// 通知中心
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    // MARK: - 初始化
    
    /// 初始化方法
    init(userSettings: UserSettings = UserSettings.shared) {
        self.userSettings = userSettings
    }
    
    // MARK: - 公共方法
    
    /// 請求通知權限
    /// - Parameter completion: 完成回調
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.error("請求通知權限失敗: \(error.localizedDescription)", category: .app)
            }
            
            // 更新用戶設置
            self.userSettings.isNotificationEnabled = granted
            
            // 回調
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// 檢查通知權限
    /// - Parameter completion: 完成回調
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            
            // 更新用戶設置
            self.userSettings.isNotificationEnabled = isAuthorized
            
            // 回調
            DispatchQueue.main.async {
                completion(isAuthorized)
            }
        }
    }
    
    /// 排程餵食提醒
    /// - Parameters:
    ///   - babyName: 寶寶名稱
    ///   - date: 提醒時間
    ///   - completion: 完成回調
    func scheduleFeedingReminder(babyName: String, date: Date, completion: @escaping (Result<String, Error>) -> Void) {
        // 檢查通知是否啟用
        guard userSettings.isNotificationEnabled else {
            completion(.failure(NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "通知未啟用"])))
            return
        }
        
        // 創建通知內容
        let content = UNMutableNotificationContent()
        content.title = "餵食提醒"
        content.body = "該給\(babyName)餵食了"
        content.sound = .default
        content.badge = 1
        
        // 創建通知觸發器
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 創建通知請求
        let identifier = "feeding-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 添加通知請求
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("排程餵食提醒失敗: \(error.localizedDescription)", category: .app)
                completion(.failure(error))
            } else {
                Logger.info("排程餵食提醒成功: \(identifier)", category: .app)
                completion(.success(identifier))
            }
        }
    }
    
    /// 排程睡眠提醒
    /// - Parameters:
    ///   - babyName: 寶寶名稱
    ///   - date: 提醒時間
    ///   - completion: 完成回調
    func scheduleSleepReminder(babyName: String, date: Date, completion: @escaping (Result<String, Error>) -> Void) {
        // 檢查通知是否啟用
        guard userSettings.isNotificationEnabled else {
            completion(.failure(NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "通知未啟用"])))
            return
        }
        
        // 創建通知內容
        let content = UNMutableNotificationContent()
        content.title = "睡眠提醒"
        content.body = "該讓\(babyName)睡覺了"
        content.sound = .default
        content.badge = 1
        
        // 創建通知觸發器
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 創建通知請求
        let identifier = "sleep-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 添加通知請求
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("排程睡眠提醒失敗: \(error.localizedDescription)", category: .app)
                completion(.failure(error))
            } else {
                Logger.info("排程睡眠提醒成功: \(identifier)", category: .app)
                completion(.success(identifier))
            }
        }
    }
    
    /// 排程尿布提醒
    /// - Parameters:
    ///   - babyName: 寶寶名稱
    ///   - date: 提醒時間
    ///   - completion: 完成回調
    func scheduleDiaperReminder(babyName: String, date: Date, completion: @escaping (Result<String, Error>) -> Void) {
        // 檢查通知是否啟用
        guard userSettings.isNotificationEnabled else {
            completion(.failure(NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "通知未啟用"])))
            return
        }
        
        // 創建通知內容
        let content = UNMutableNotificationContent()
        content.title = "尿布提醒"
        content.body = "該給\(babyName)換尿布了"
        content.sound = .default
        content.badge = 1
        
        // 創建通知觸發器
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 創建通知請求
        let identifier = "diaper-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 添加通知請求
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("排程尿布提醒失敗: \(error.localizedDescription)", category: .app)
                completion(.failure(error))
            } else {
                Logger.info("排程尿布提醒成功: \(identifier)", category: .app)
                completion(.success(identifier))
            }
        }
    }
    
    /// 排程AI分析完成提醒
    /// - Parameters:
    ///   - analysisType: 分析類型
    ///   - completion: 完成回調
    func scheduleAnalysisCompletedNotification(analysisType: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 檢查通知是否啟用
        guard userSettings.isNotificationEnabled else {
            completion(.failure(NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "通知未啟用"])))
            return
        }
        
        // 創建通知內容
        let content = UNMutableNotificationContent()
        content.title = "AI分析完成"
        content.body = "\(analysisType)分析已完成，點擊查看結果"
        content.sound = .default
        content.badge = 1
        
        // 創建通知觸發器（立即觸發）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // 創建通知請求
        let identifier = "analysis-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 添加通知請求
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("排程AI分析完成提醒失敗: \(error.localizedDescription)", category: .app)
                completion(.failure(error))
            } else {
                Logger.info("排程AI分析完成提醒成功: \(identifier)", category: .app)
                completion(.success(identifier))
            }
        }
    }
    
    /// 取消通知
    /// - Parameter identifier: 通知標識符
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        Logger.info("取消通知: \(identifier)", category: .app)
    }
    
    /// 取消所有通知
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        Logger.info("取消所有通知", category: .app)
    }
}
