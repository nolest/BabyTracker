import Foundation

/// 餵食類型枚舉
enum FeedingType: String, Codable, CaseIterable {
    case breastfeeding = "breastfeeding"       // 母乳餵食
    case bottleBreastMilk = "bottleBreastMilk" // 瓶餵母乳
    case formula = "formula"                   // 配方奶
    case solidFood = "solidFood"               // 固體食物
    case water = "water"                       // 水
    case other = "other"                       // 其他
    
    var localizedName: String {
        switch self {
        case .breastfeeding:
            return NSLocalizedString("母乳餵食", comment: "Breastfeeding type")
        case .bottleBreastMilk:
            return NSLocalizedString("瓶餵母乳", comment: "Bottle breast milk type")
        case .formula:
            return NSLocalizedString("配方奶", comment: "Formula type")
        case .solidFood:
            return NSLocalizedString("固體食物", comment: "Solid food type")
        case .water:
            return NSLocalizedString("水", comment: "Water type")
        case .other:
            return NSLocalizedString("其他", comment: "Other feeding type")
        }
    }
    
    var icon: String {
        switch self {
        case .breastfeeding:
            return "heart.fill"
        case .bottleBreastMilk:
            return "drop.fill"
        case .formula:
            return "bottle.fill"
        case .solidFood:
            return "fork.knife"
        case .water:
            return "drop"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}
