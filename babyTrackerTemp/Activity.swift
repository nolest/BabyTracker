import Foundation

/// 活動記錄模型
struct Activity: Identifiable, Codable {
    let id: String
    let babyId: String
    let type: ActivityType
    let startTime: Date
    let endTime: Date?
    let notes: String?
    
    init(id: String = UUID().uuidString,
         babyId: String,
         type: ActivityType,
         startTime: Date,
         endTime: Date? = nil,
         notes: String? = nil) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
    
    /// 活動持續時間（秒），如果沒有結束時間則返回nil
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}
