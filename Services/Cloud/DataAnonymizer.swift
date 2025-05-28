import Foundation
import CryptoKit

/// 數據匿名化工具
class DataAnonymizer {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = DataAnonymizer()
    
    // MARK: - 屬性
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    /// 設備標識符
    private let deviceIdentifier: DeviceIdentifier
    
    // MARK: - 初始化
    
    /// 初始化方法
    init(userSettings: UserSettings = UserSettings.shared, deviceIdentifier: DeviceIdentifier = DeviceIdentifier.shared) {
        self.userSettings = userSettings
        self.deviceIdentifier = deviceIdentifier
    }
    
    // MARK: - 公共方法
    
    /// 匿名化寶寶數據
    /// - Parameter baby: 寶寶數據
    /// - Returns: 匿名化後的寶寶數據
    func anonymizeBaby(_ baby: Baby) -> Baby {
        // 檢查是否啟用數據匿名化
        guard userSettings.isDataAnonymizationEnabled else {
            return baby
        }
        
        // 匿名化寶寶數據
        return Baby(
            id: anonymizeIdentifier(baby.id),
            name: anonymizeName(baby.name),
            birthDate: baby.birthDate,
            gender: baby.gender,
            photoURL: nil // 不上傳照片
        )
    }
    
    /// 匿名化睡眠記錄
    /// - Parameter sleepRecord: 睡眠記錄
    /// - Returns: 匿名化後的睡眠記錄
    func anonymizeSleepRecord(_ sleepRecord: SleepRecord) -> SleepRecord {
        // 檢查是否啟用數據匿名化
        guard userSettings.isDataAnonymizationEnabled else {
            return sleepRecord
        }
        
        // 匿名化睡眠記錄
        return SleepRecord(
            id: anonymizeIdentifier(sleepRecord.id),
            babyId: anonymizeIdentifier(sleepRecord.babyId),
            startTime: sleepRecord.startTime,
            endTime: sleepRecord.endTime,
            quality: sleepRecord.quality,
            environmentFactors: sleepRecord.environmentFactors,
            interruptions: sleepRecord.interruptions,
            notes: nil // 移除筆記
        )
    }
    
    /// 匿名化多個睡眠記錄
    /// - Parameter sleepRecords: 睡眠記錄數組
    /// - Returns: 匿名化後的睡眠記錄數組
    func anonymizeSleepRecords(_ sleepRecords: [SleepRecord]) -> [SleepRecord] {
        return sleepRecords.map { anonymizeSleepRecord($0) }
    }
    
    /// 匿名化餵食記錄
    /// - Parameter feedingRecord: 餵食記錄
    /// - Returns: 匿名化後的餵食記錄
    func anonymizeFeedingRecord(_ feedingRecord: FeedingRecord) -> FeedingRecord {
        // 檢查是否啟用數據匿名化
        guard userSettings.isDataAnonymizationEnabled else {
            return feedingRecord
        }
        
        // 匿名化餵食記錄
        return FeedingRecord(
            id: anonymizeIdentifier(feedingRecord.id),
            babyId: anonymizeIdentifier(feedingRecord.babyId),
            startTime: feedingRecord.startTime,
            type: feedingRecord.type,
            amount: feedingRecord.amount,
            notes: nil // 移除筆記
        )
    }
    
    /// 匿名化活動記錄
    /// - Parameter activity: 活動記錄
    /// - Returns: 匿名化後的活動記錄
    func anonymizeActivity(_ activity: Activity) -> Activity {
        // 檢查是否啟用數據匿名化
        guard userSettings.isDataAnonymizationEnabled else {
            return activity
        }
        
        // 匿名化活動記錄
        return Activity(
            id: anonymizeIdentifier(activity.id),
            babyId: anonymizeIdentifier(activity.babyId),
            startTime: activity.startTime,
            type: activity.type,
            notes: nil // 移除筆記
        )
    }
    
    /// 匿名化作息記錄
    /// - Parameters:
    ///   - sleepRecords: 睡眠記錄
    ///   - feedingRecords: 餵食記錄
    ///   - activities: 活動記錄
    /// - Returns: 匿名化的作息數據
    func anonymizeRoutineRecords(
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        activities: [Activity]
    ) -> [String: Any] {
        // 匿名化所有記錄
        let anonymizedSleepRecords = sleepRecords.map { anonymizeSleepRecord($0) }
        let anonymizedFeedingRecords = feedingRecords.map { anonymizeFeedingRecord($0) }
        let anonymizedActivities = activities.map { anonymizeActivity($0) }
        
        // 返回匿名化數據字典
        return [
            "sleepRecords": anonymizedSleepRecords,
            "feedingRecords": anonymizedFeedingRecords,
            "activities": anonymizedActivities
        ]
    }
    
    /// 匿名化成長記錄
    /// - Parameter growth: 成長記錄
    /// - Returns: 匿名化後的成長記錄
    func anonymizeGrowth(_ growth: Growth) -> Growth {
        // 檢查是否啟用數據匿名化
        guard userSettings.isDataAnonymizationEnabled else {
            return growth
        }
        
        // 匿名化成長記錄
        return Growth(
            id: anonymizeIdentifier(growth.id),
            babyId: anonymizeIdentifier(growth.babyId),
            date: growth.date,
            height: growth.height,
            weight: growth.weight,
            headCircumference: growth.headCircumference
        )
    }
    
    // MARK: - 私有方法
    
    /// 匿名化標識符
    /// - Parameter identifier: 標識符
    /// - Returns: 匿名化後的標識符
    private func anonymizeIdentifier(_ identifier: String) -> String {
        // 獲取設備標識符
        let deviceId = deviceIdentifier.getDeviceIdentifier()
        
        // 將設備標識符與原始標識符組合
        let combinedString = deviceId + identifier
        
        // 計算SHA-256哈希
        let inputData = Data(combinedString.utf8)
        let hashed = SHA256.hash(data: inputData)
        
        // 將哈希轉換為字符串
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 匿名化名稱
    /// - Parameter name: 名稱
    /// - Returns: 匿名化後的名稱
    private func anonymizeName(_ name: String) -> String {
        // 如果名稱為空，返回"匿名"
        guard !name.isEmpty else {
            return "匿名"
        }
        
        // 獲取名稱的第一個字符
        let firstChar = name.prefix(1)
        
        // 返回"某某"格式的名稱
        return "\(firstChar)某"
    }
}
