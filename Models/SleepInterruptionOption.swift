import Foundation

/// 睡眠中斷選項
enum SleepInterruptionOption: Int, CaseIterable {
    /// 無
    case none = 0
    
    /// 哭鬧
    case crying = 1
    
    /// 餵食
    case feeding = 2
    
    /// 換尿布
    case diaper = 3
    
    /// 其他
    case other = 4
    
    /// 顯示名稱
    var displayName: String {
        switch self {
        case .none:
            return "無"
        case .crying:
            return "哭鬧"
        case .feeding:
            return "餵食"
        case .diaper:
            return "換尿布"
        case .other:
            return "其他"
        }
    }
} 