import Foundation

/// 分析錯誤
enum AnalysisError: Error {
    /// 數據不足
    case insufficientData
    
    /// 無效的數據
    case invalidData
    
    /// 分析失敗
    case analysisFailed(String)
    
    /// 雲端服務不可用
    case cloudServiceUnavailable
    
    /// 請求限制
    case requestLimitReached
    
    /// 未知錯誤
    case unknown(Error?)
    
    /// AI分析已禁用
    case aiAnalysisDisabled
    
    /// 分析器不可用
    case analyzerNotAvailable
    
    /// 處理錯誤
    case processingError
    
    /// 錯誤描述
    var localizedDescription: String {
        switch self {
        case .insufficientData:
            return "數據不足，無法進行分析"
        case .invalidData:
            return "無效的數據"
        case .analysisFailed(let message):
            return "分析失敗: \(message)"
        case .cloudServiceUnavailable:
            return "雲端服務不可用"
        case .requestLimitReached:
            return "已達到請求限制"
        case .unknown(let error):
            return error?.localizedDescription ?? "未知分析錯誤"
        case .aiAnalysisDisabled:
            return "AI分析功能已禁用"
        case .analyzerNotAvailable:
            return "分析器不可用"
        case .processingError:
            return "數據處理錯誤"
        }
    }
}
