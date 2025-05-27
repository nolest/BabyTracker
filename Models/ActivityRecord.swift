import Foundation

/// 活動記錄（用於分析）
struct ActivityRecord {
    let id: String
    let type: ActivityType
    let startTime: Date
    let endTime: Date
    let notes: String?
    
    init(id: String,
         type: ActivityType,
         startTime: Date,
         endTime: Date,
         notes: String? = nil) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
}
