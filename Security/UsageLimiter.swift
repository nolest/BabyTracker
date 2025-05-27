import Foundation

/// 使用限制器
class UsageLimiter {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = UsageLimiter()
    
    // MARK: - 屬性
    
    /// 用戶默認值鍵 - 每小時請求計數
    private let hourlyRequestsKey = "hourlyRequests"
    
    /// 用戶默認值鍵 - 每日請求計數
    private let dailyRequestsKey = "dailyRequests"
    
    /// 用戶默認值鍵 - 小時計數重置時間
    private let hourlyResetTimeKey = "hourlyResetTime"
    
    /// 用戶默認值鍵 - 日計數重置時間
    private let dailyResetTimeKey = "dailyResetTime"
    
    /// 每小時最大請求次數
    private let maxRequestsPerHour = Constants.AI.maxRequestsPerHour
    
    /// 每天最大請求次數
    private let maxRequestsPerDay = Constants.AI.maxRequestsPerDay
    
    // MARK: - 初始化
    
    /// 私有初始化方法
    private init() {
        // 檢查是否需要重置計數器
        checkAndResetCounters()
    }
    
    // MARK: - 公共方法
    
    /// 檢查是否可以進行請求
    /// - Returns: 是否可以進行請求
    func canMakeRequest() -> Bool {
        // 檢查是否需要重置計數器
        checkAndResetCounters()
        
        // 獲取當前計數
        let hourlyRequests = UserDefaults.standard.integer(forKey: hourlyRequestsKey)
        let dailyRequests = UserDefaults.standard.integer(forKey: dailyRequestsKey)
        
        // 檢查是否超過限制
        return hourlyRequests < maxRequestsPerHour && dailyRequests < maxRequestsPerDay
    }
    
    /// 記錄請求
    func recordRequest() {
        // 檢查是否需要重置計數器
        checkAndResetCounters()
        
        // 獲取當前計數
        var hourlyRequests = UserDefaults.standard.integer(forKey: hourlyRequestsKey)
        var dailyRequests = UserDefaults.standard.integer(forKey: dailyRequestsKey)
        
        // 增加計數
        hourlyRequests += 1
        dailyRequests += 1
        
        // 保存計數
        UserDefaults.standard.set(hourlyRequests, forKey: hourlyRequestsKey)
        UserDefaults.standard.set(dailyRequests, forKey: dailyRequestsKey)
    }
    
    /// 獲取剩餘請求次數
    /// - Returns: 剩餘請求次數（每小時，每天）
    func getRemainingRequests() -> (hourly: Int, daily: Int) {
        // 檢查是否需要重置計數器
        checkAndResetCounters()
        
        // 獲取當前計數
        let hourlyRequests = UserDefaults.standard.integer(forKey: hourlyRequestsKey)
        let dailyRequests = UserDefaults.standard.integer(forKey: dailyRequestsKey)
        
        // 計算剩餘次數
        let hourlyRemaining = max(0, maxRequestsPerHour - hourlyRequests)
        let dailyRemaining = max(0, maxRequestsPerDay - dailyRequests)
        
        return (hourlyRemaining, dailyRemaining)
    }
    
    /// 重置計數器
    func resetCounters() {
        // 重置計數
        UserDefaults.standard.set(0, forKey: hourlyRequestsKey)
        UserDefaults.standard.set(0, forKey: dailyRequestsKey)
        
        // 設置重置時間
        let now = Date()
        UserDefaults.standard.set(now, forKey: hourlyResetTimeKey)
        UserDefaults.standard.set(now, forKey: dailyResetTimeKey)
    }
    
    // MARK: - 私有方法
    
    /// 檢查並重置計數器
    private func checkAndResetCounters() {
        let now = Date()
        
        // 檢查小時計數器
        if let hourlyResetTime = UserDefaults.standard.object(forKey: hourlyResetTimeKey) as? Date {
            if now.timeIntervalSince(hourlyResetTime) >= Constants.Time.oneHour {
                // 重置小時計數
                UserDefaults.standard.set(0, forKey: hourlyRequestsKey)
                UserDefaults.standard.set(now, forKey: hourlyResetTimeKey)
            }
        } else {
            // 首次設置
            UserDefaults.standard.set(now, forKey: hourlyResetTimeKey)
        }
        
        // 檢查日計數器
        if let dailyResetTime = UserDefaults.standard.object(forKey: dailyResetTimeKey) as? Date {
            if now.timeIntervalSince(dailyResetTime) >= Constants.Time.oneDay {
                // 重置日計數
                UserDefaults.standard.set(0, forKey: dailyRequestsKey)
                UserDefaults.standard.set(now, forKey: dailyResetTimeKey)
            }
        } else {
            // 首次設置
            UserDefaults.standard.set(now, forKey: dailyResetTimeKey)
        }
    }
}
