import Foundation

/// 網絡錯誤
enum NetworkError: Error {
    /// 無網絡連接
    case noConnection
    
    /// 無網絡連接（同noConnection，用於兼容性）
    case noInternetConnection
    
    /// 請求超時
    case timeout
    
    /// 服務器錯誤
    case serverError(Int)
    
    /// 無效的URL
    case invalidURL
    
    /// 無效的響應
    case invalidResponse
    
    /// 解碼錯誤
    case decodingError(Error)
    
    /// 未知錯誤
    case unknown(Error?)
    
    /// 錯誤描述
    var localizedDescription: String {
        switch self {
        case .noConnection:
            return "無網絡連接"
        case .noInternetConnection:
            return "無網絡連接"
        case .timeout:
            return "請求超時"
        case .serverError(let statusCode):
            return "服務器錯誤: \(statusCode)"
        case .invalidURL:
            return "無效的URL"
        case .invalidResponse:
            return "無效的響應"
        case .decodingError(let error):
            return "解碼錯誤: \(error.localizedDescription)"
        case .unknown(let error):
            return error?.localizedDescription ?? "未知網絡錯誤"
        }
    }
}
