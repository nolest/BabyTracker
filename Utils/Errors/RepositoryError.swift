import Foundation

/// 倉庫錯誤
enum RepositoryError: Error {
    /// 未找到數據
    case notFound
    
    /// 無效的數據
    case invalidData
    
    /// 數據庫錯誤
    case databaseError(String)
    
    /// 權限錯誤
    case permissionDenied
    
    /// 重複數據
    case duplicateData
    
    /// 未知錯誤
    case unknown(Error?)
    
    /// 錯誤描述
    var localizedDescription: String {
        switch self {
        case .notFound:
            return "未找到數據"
        case .invalidData:
            return "無效的數據"
        case .databaseError(let message):
            return "數據庫錯誤: \(message)"
        case .permissionDenied:
            return "權限被拒絕"
        case .duplicateData:
            return "數據重複"
        case .unknown(let error):
            return error?.localizedDescription ?? "未知錯誤"
        }
    }
}
