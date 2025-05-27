import Foundation

/// 雲端服務錯誤
enum CloudError: Error {
    /// 無網絡連接
    case noConnection
    
    /// 認證失敗
    case authenticationFailed
    
    /// API密鑰無效
    case invalidAPIKey
    
    /// 請求限制
    case requestLimitReached
    
    /// 服務不可用
    case serviceUnavailable
    
    /// 響應解析失敗
    case responseParsingFailed
    
    /// 未知錯誤
    case unknown(Error?)
    
    /// 錯誤描述
    var localizedDescription: String {
        switch self {
        case .noConnection:
            return "無網絡連接"
        case .authenticationFailed:
            return "認證失敗"
        case .invalidAPIKey:
            return "API密鑰無效"
        case .requestLimitReached:
            return "已達到請求限制"
        case .serviceUnavailable:
            return "雲端服務不可用"
        case .responseParsingFailed:
            return "響應解析失敗"
        case .unknown(let error):
            return error?.localizedDescription ?? "未知雲端錯誤"
        }
    }
}
