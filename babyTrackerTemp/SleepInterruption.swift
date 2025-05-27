import Foundation

/// 睡眠中斷
struct SleepInterruption: Codable {
    let duration: TimeInterval  // 中斷持續時間（秒）
    let reason: String?  // 中斷原因
    
    init(duration: TimeInterval, reason: String? = nil) {
        self.duration = duration
        self.reason = reason
    }
}
