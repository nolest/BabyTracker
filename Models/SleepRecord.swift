import Foundation

/// 睡眠記錄模型
struct SleepRecord: Identifiable, Codable {
    let id: String
    let babyId: String
    let startTime: Date
    let endTime: Date
    let quality: Int?  // 0-100
    let environmentFactors: EnvironmentFactors?
    let interruptions: [SleepInterruption]
    let notes: String?
    
    init(id: String = UUID().uuidString,
         babyId: String,
         startTime: Date,
         endTime: Date,
         quality: Int? = nil,
         environmentFactors: EnvironmentFactors? = nil,
         interruptions: [SleepInterruption] = [],
         notes: String? = nil) {
        self.id = id
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
        self.environmentFactors = environmentFactors
        self.interruptions = interruptions
        self.notes = notes
    }
    
    /// 睡眠持續時間（秒）
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 睡眠持續時間（小時）
    var durationHours: Double {
        return duration / 3600
    }
    
    /// 是否為夜間睡眠
    var isNightSleep: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        return hour >= 19 || hour < 7
    }
}
