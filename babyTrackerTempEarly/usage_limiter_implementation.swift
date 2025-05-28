// UsageLimiter.swift
// 寶寶生活記錄專業版（Baby Tracker）
// API使用限制實現

import Foundation

/// API使用限制器，負責控制API的使用頻率
class UsageLimiter {
    // MARK: - 單例
    static let shared = UsageLimiter()
    private init() {
        loadUsageHistory()
    }
    
    // MARK: - 常量
    private let usageHistoryKey = "com.babytracker.api_usage_history"
    private let maxHourlyRequests = 10
    private let maxDailyRequests = 30
    private let consecutiveRequestLimit = 3
    private let consecutiveRequestCooldown: TimeInterval = 5 * 60 // 5分鐘
    
    // MARK: - 屬性
    private var usageHistory: [Date] = []
    private var rateLimitedKeys: [String: Date] = [:] // Key: API Key, Value: 限流到期時間
    
    // MARK: - 公共方法
    
    /// 檢查是否可以發送API請求
    func canMakeRequest() -> Bool {
        cleanupOldRecords()
        
        let hourAgo = Date().addingTimeInterval(-3600)
        let dayAgo = Date().addingTimeInterval(-86400)
        
        let hourlyRequests = usageHistory.filter { $0 >= hourAgo }.count
        let dailyRequests = usageHistory.filter { $0 >= dayAgo }.count
        
        // 檢查小時限制
        if hourlyRequests >= maxHourlyRequests {
            return false
        }
        
        // 檢查日限制
        if dailyRequests >= maxDailyRequests {
            return false
        }
        
        // 檢查連續請求限制
        if let consecutiveRequestInfo = checkConsecutiveRequests() {
            if consecutiveRequestInfo.count >= consecutiveRequestLimit && 
               Date().timeIntervalSince(consecutiveRequestInfo.lastRequestTime) < consecutiveRequestCooldown {
                return false
            }
        }
        
        return true
    }
    
    /// 檢查特定API Key是否被限流
    func isKeyRateLimited(_ apiKey: String) -> Bool {
        if let expiryTime = rateLimitedKeys[apiKey], expiryTime > Date() {
            return true
        }
        
        // 清理過期的限流記錄
        rateLimitedKeys = rateLimitedKeys.filter { $0.value > Date() }
        return false
    }
    
    /// 記錄API使用
    func recordUsage() {
        usageHistory.append(Date())
        saveUsageHistory()
    }
    
    /// 記錄API限流事件
    func recordRateLimiting(forKey apiKey: String) {
        // 實現指數退避策略
        let backoffTime: TimeInterval
        
        if let existingExpiry = rateLimitedKeys[apiKey] {
            // 如果已經被限流，增加限流時間
            let currentBackoff = existingExpiry.timeIntervalSinceNow
            backoffTime = min(currentBackoff * 2, 3600) // 最多限流1小時
        } else {
            // 首次限流，從5分鐘開始
            backoffTime = 5 * 60
        }
        
        rateLimitedKeys[apiKey] = Date().addingTimeInterval(backoffTime)
    }
    
    /// 獲取使用統計
    func getUsageStatistics() -> (hourly: Int, daily: Int, hourlyRemaining: Int, dailyRemaining: Int, nextAllowedTime: Date?) {
        cleanupOldRecords()
        
        let hourAgo = Date().addingTimeInterval(-3600)
        let dayAgo = Date().addingTimeInterval(-86400)
        
        let hourlyRequests = usageHistory.filter { $0 >= hourAgo }.count
        let dailyRequests = usageHistory.filter { $0 >= dayAgo }.count
        
        var nextAllowedTime: Date? = nil
        
        // 如果達到小時限制，計算下次允許時間
        if hourlyRequests >= maxHourlyRequests {
            let oldestHourlyRequest = usageHistory.filter { $0 >= hourAgo }.min()
            if let oldestTime = oldestHourlyRequest {
                nextAllowedTime = oldestTime.addingTimeInterval(3600)
            }
        }
        
        // 如果達到連續請求限制，計算冷卻期結束時間
        if let consecutiveInfo = checkConsecutiveRequests(), 
           consecutiveInfo.count >= consecutiveRequestLimit {
            let cooldownEndTime = consecutiveInfo.lastRequestTime.addingTimeInterval(consecutiveRequestCooldown)
            
            // 取較晚的時間
            if let current = nextAllowedTime {
                nextAllowedTime = max(current, cooldownEndTime)
            } else {
                nextAllowedTime = cooldownEndTime
            }
        }
        
        return (
            hourly: hourlyRequests,
            daily: dailyRequests,
            hourlyRemaining: max(0, maxHourlyRequests - hourlyRequests),
            dailyRemaining: max(0, maxDailyRequests - dailyRequests),
            nextAllowedTime: nextAllowedTime
        )
    }
    
    // MARK: - 私有方法
    
    /// 清理舊記錄
    private func cleanupOldRecords() {
        let dayAgo = Date().addingTimeInterval(-86400)
        usageHistory = usageHistory.filter { $0 >= dayAgo }
    }
    
    /// 檢查連續請求
    private func checkConsecutiveRequests() -> (count: Int, lastRequestTime: Date)? {
        guard !usageHistory.isEmpty else {
            return nil
        }
        
        // 按時間排序
        let sortedHistory = usageHistory.sorted()
        
        // 獲取最近的請求
        guard let lastRequestTime = sortedHistory.last else {
            return nil
        }
        
        // 計算5分鐘內的請求數
        let fiveMinutesAgo = lastRequestTime.addingTimeInterval(-5 * 60)
        let recentRequests = sortedHistory.filter { $0 >= fiveMinutesAgo }
        
        return (recentRequests.count, lastRequestTime)
    }
    
    /// 保存使用歷史
    private func saveUsageHistory() {
        let timestamps = usageHistory.map { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(timestamps, forKey: usageHistoryKey)
    }
    
    /// 加載使用歷史
    private func loadUsageHistory() {
        if let timestamps = UserDefaults.standard.array(forKey: usageHistoryKey) as? [Double] {
            usageHistory = timestamps.map { Date(timeIntervalSince1970: $0) }
            cleanupOldRecords()
        }
    }
}
