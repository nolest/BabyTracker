import Foundation

/// 活動類型枚舉
enum ActivityType: String, Codable, CaseIterable {
    case sleep = "sleep"           // 睡眠
    case feeding = "feeding"       // 餵食
    case diaper = "diaper"         // 換尿布
    case bath = "bath"             // 洗澡
    case play = "play"             // 玩耍
    case tummyTime = "tummyTime"   // 趴著時間
    case outdoors = "outdoors"     // 戶外活動
    case medication = "medication" // 用藥
    case other = "other"           // 其他
    
    var localizedName: String {
        switch self {
        case .sleep:
            return NSLocalizedString("睡眠", comment: "Sleep activity type")
        case .feeding:
            return NSLocalizedString("餵食", comment: "Feeding activity type")
        case .diaper:
            return NSLocalizedString("換尿布", comment: "Diaper activity type")
        case .bath:
            return NSLocalizedString("洗澡", comment: "Bath activity type")
        case .play:
            return NSLocalizedString("玩耍", comment: "Play activity type")
        case .tummyTime:
            return NSLocalizedString("趴著時間", comment: "Tummy time activity type")
        case .outdoors:
            return NSLocalizedString("戶外活動", comment: "Outdoors activity type")
        case .medication:
            return NSLocalizedString("用藥", comment: "Medication activity type")
        case .other:
            return NSLocalizedString("其他", comment: "Other activity type")
        }
    }
    
    var icon: String {
        switch self {
        case .sleep:
            return "moon.zzz.fill"
        case .feeding:
            return "bottle.fill"
        case .diaper:
            return "heart.fill"
        case .bath:
            return "drop.fill"
        case .play:
            return "gamecontroller.fill"
        case .tummyTime:
            return "figure.walk"
        case .outdoors:
            return "sun.max.fill"
        case .medication:
            return "pills.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}
