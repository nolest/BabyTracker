import Foundation

/// 餵食記錄模型
struct FeedingRecord: Identifiable, Codable {
    let id: String
    let babyId: String
    let startTime: Date
    let endTime: Date?
    let type: FeedingType
    let amount: Double?  // 毫升或克
    let notes: String?
    
    init(id: String = UUID().uuidString,
         babyId: String,
         startTime: Date,
         endTime: Date? = nil,
         type: FeedingType,
         amount: Double? = nil,
         notes: String? = nil) {
        self.id = id
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.amount = amount
        self.notes = notes
    }
    
    /// 餵食持續時間（秒），如果沒有結束時間則返回nil
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}
