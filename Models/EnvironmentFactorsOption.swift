import Foundation

/// 環境因素選項
enum EnvironmentFactorsOption: Int, CaseIterable {
    /// 無
    case none = 0
    
    /// 噪音
    case noise = 1
    
    /// 光線
    case light = 2
    
    /// 溫度
    case temperature = 3
    
    /// 其他
    case other = 4
    
    /// 顯示名稱
    var displayName: String {
        switch self {
        case .none:
            return "無"
        case .noise:
            return "噪音"
        case .light:
            return "光線"
        case .temperature:
            return "溫度"
        case .other:
            return "其他"
        }
    }
} 