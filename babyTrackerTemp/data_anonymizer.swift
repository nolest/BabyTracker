// DataAnonymizer.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：Deepseek API整合
// 數據匿名化處理

import Foundation
import CryptoKit

/// 負責對發送到雲端的數據進行匿名化處理
class DataAnonymizer {
    // MARK: - 單例模式
    static let shared = DataAnonymizer()
    
    private init() {}
    
    // MARK: - 匿名化方法
    
    /// 匿名化睡眠記錄數據
    /// - Parameter records: 原始睡眠記錄
    /// - Returns: 匿名化後的數據
    func anonymizeSleepRecords(_ records: [SleepRecord]) -> AnonymizedSleepData {
        // 獲取基準時間（最早記錄的時間）
        let baseTime = getBaseTime(from: records.map { $0.startTime })
        
        // 匿名化處理
        let anonymizedRecords = records.map { record -> AnonymizedSleepRecord in
            return AnonymizedSleepRecord(
                recordId: generateAnonymousId(from: record.id),
                relativeStartTime: record.startTime.timeIntervalSince(baseTime),
                relativeEndTime: record.endTime.timeIntervalSince(baseTime),
                quality: record.quality,
                environmentFactors: anonymizeEnvironmentFactors(record.environmentFactors),
                interruptions: record.interruptions.map { anonymizeInterruption($0) },
                notes: anonymizeNotes(record.notes)
            )
        }
        
        // 計算寶寶年齡（月）但不包含具體出生日期
        let ageInMonths = calculateAgeInMonths(babyId: records.first?.babyId)
        
        return AnonymizedSleepData(
            deviceId: generateDeviceId(),
            sessionId: UUID().uuidString,
            recordCount: records.count,
            timeSpanDays: calculateTimeSpanDays(records: records),
            babyAgeMonths: ageInMonths,
            records: anonymizedRecords
        )
    }
    
    /// 匿名化作息記錄數據
    /// - Parameter records: 原始作息記錄
    /// - Returns: 匿名化後的數據
    func anonymizeRoutineRecords(_ activities: [Activity]) -> AnonymizedRoutineData {
        // 獲取基準時間（最早記錄的時間）
        let baseTime = getBaseTime(from: activities.map { $0.startTime })
        
        // 匿名化處理
        let anonymizedActivities = activities.map { activity -> AnonymizedActivity in
            return AnonymizedActivity(
                activityId: generateAnonymousId(from: activity.id),
                activityType: activity.type.rawValue,
                relativeStartTime: activity.startTime.timeIntervalSince(baseTime),
                relativeEndTime: activity.endTime?.timeIntervalSince(baseTime),
                duration: activity.endTime?.timeIntervalSince(activity.startTime),
                notes: anonymizeNotes(activity.notes)
            )
        }
        
        // 計算寶寶年齡（月）但不包含具體出生日期
        let ageInMonths = calculateAgeInMonths(babyId: activities.first?.babyId)
        
        return AnonymizedRoutineData(
            deviceId: generateDeviceId(),
            sessionId: UUID().uuidString,
            recordCount: activities.count,
            timeSpanDays: calculateTimeSpanDays(activities: activities),
            babyAgeMonths: ageInMonths,
            activities: anonymizedActivities
        )
    }
    
    // MARK: - 輔助方法
    
    /// 獲取基準時間（最早記錄的時間）
    /// - Parameter dates: 日期數組
    /// - Returns: 基準時間
    private func getBaseTime(from dates: [Date]) -> Date {
        return dates.min() ?? Date()
    }
    
    /// 生成匿名ID
    /// - Parameter originalId: 原始ID
    /// - Returns: 匿名化後的ID
    private func generateAnonymousId(from originalId: String) -> String {
        // 使用SHA-256哈希原始ID，然後取前8個字符
        if let data = originalId.data(using: .utf8) {
            let hash = SHA256.hash(data: data)
            return hash.prefix(8).compactMap { String(format: "%02x", $0) }.joined()
        }
        return UUID().uuidString.prefix(8).description
    }
    
    /// 生成設備ID（保持一致但匿名）
    /// - Returns: 匿名化的設備ID
    private func generateDeviceId() -> String {
        // 使用設備標識符生成一個一致但匿名的ID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        // 使用SHA-256哈希設備ID，然後取前12個字符
        if let data = deviceId.data(using: .utf8) {
            let hash = SHA256.hash(data: data)
            return hash.prefix(12).compactMap { String(format: "%02x", $0) }.joined()
        }
        return UUID().uuidString.prefix(12).description
    }
    
    /// 匿名化環境因素
    /// - Parameter factors: 原始環境因素
    /// - Returns: 匿名化後的環境因素
    private func anonymizeEnvironmentFactors(_ factors: EnvironmentFactors?) -> AnonymizedEnvironmentFactors? {
        guard let factors = factors else { return nil }
        
        return AnonymizedEnvironmentFactors(
            lightLevel: factors.lightLevel,
            noiseLevel: factors.noiseLevel,
            temperature: factors.temperature,
            humidity: factors.humidity
        )
    }
    
    /// 匿名化中斷記錄
    /// - Parameter interruption: 原始中斷記錄
    /// - Returns: 匿名化後的中斷記錄
    private func anonymizeInterruption(_ interruption: SleepInterruption) -> AnonymizedSleepInterruption {
        return AnonymizedSleepInterruption(
            duration: interruption.duration,
            reason: anonymizeInterruptionReason(interruption.reason)
        )
    }
    
    /// 匿名化中斷原因
    /// - Parameter reason: 原始中斷原因
    /// - Returns: 匿名化後的中斷原因
    private func anonymizeInterruptionReason(_ reason: String?) -> String? {
        guard let reason = reason else { return nil }
        
        // 移除可能包含個人信息的文本，保留常見原因
        let commonReasons = ["餓了", "尿布", "噪音", "不舒服", "做夢", "其他"]
        
        for commonReason in commonReasons {
            if reason.contains(commonReason) {
                return commonReason
            }
        }
        
        return "其他"
    }
    
    /// 匿名化筆記
    /// - Parameter notes: 原始筆記
    /// - Returns: 匿名化後的筆記
    private func anonymizeNotes(_ notes: String?) -> String? {
        guard let notes = notes, !notes.isEmpty else { return nil }
        
        // 移除可能包含個人信息的文本，只保留長度信息
        return "有筆記（\(notes.count)字）"
    }
    
    /// 計算寶寶年齡（月）
    /// - Parameter babyId: 寶寶ID
    /// - Returns: 寶寶年齡（月）
    private func calculateAgeInMonths(babyId: String?) -> Int? {
        guard let babyId = babyId else { return nil }
        
        // 這裡應該從數據庫獲取寶寶出生日期，然後計算年齡
        // 為了匿名化，我們只返回月齡，不返回具體出生日期
        // 這是一個模擬實現
        return 12 // 假設寶寶1歲
    }
    
    /// 計算記錄跨越的天數
    /// - Parameter records: 睡眠記錄
    /// - Returns: 跨越的天數
    private func calculateTimeSpanDays(records: [SleepRecord]) -> Int {
        guard let firstDate = records.map({ $0.startTime }).min(),
              let lastDate = records.map({ $0.endTime }).max() else {
            return 0
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstDate, to: lastDate)
        return components.day ?? 0
    }
    
    /// 計算活動記錄跨越的天數
    /// - Parameter activities: 活動記錄
    /// - Returns: 跨越的天數
    private func calculateTimeSpanDays(activities: [Activity]) -> Int {
        guard let firstDate = activities.map({ $0.startTime }).min(),
              let lastDate = activities.compactMap({ $0.endTime }).max() ?? activities.map({ $0.startTime }).max() else {
            return 0
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstDate, to: lastDate)
        return components.day ?? 0
    }
}

// MARK: - 匿名化數據結構

/// 匿名化的睡眠數據
struct AnonymizedSleepData: Codable {
    let deviceId: String
    let sessionId: String
    let recordCount: Int
    let timeSpanDays: Int
    let babyAgeMonths: Int?
    let records: [AnonymizedSleepRecord]
}

/// 匿名化的睡眠記錄
struct AnonymizedSleepRecord: Codable {
    let recordId: String
    let relativeStartTime: TimeInterval
    let relativeEndTime: TimeInterval
    let quality: Int?
    let environmentFactors: AnonymizedEnvironmentFactors?
    let interruptions: [AnonymizedSleepInterruption]
    let notes: String?
}

/// 匿名化的環境因素
struct AnonymizedEnvironmentFactors: Codable {
    let lightLevel: Int?
    let noiseLevel: Int?
    let temperature: Double?
    let humidity: Double?
}

/// 匿名化的睡眠中斷
struct AnonymizedSleepInterruption: Codable {
    let duration: TimeInterval
    let reason: String?
}

/// 匿名化的作息數據
struct AnonymizedRoutineData: Codable {
    let deviceId: String
    let sessionId: String
    let recordCount: Int
    let timeSpanDays: Int
    let babyAgeMonths: Int?
    let activities: [AnonymizedActivity]
}

/// 匿名化的活動
struct AnonymizedActivity: Codable {
    let activityId: String
    let activityType: String
    let relativeStartTime: TimeInterval
    let relativeEndTime: TimeInterval?
    let duration: TimeInterval?
    let notes: String?
}
