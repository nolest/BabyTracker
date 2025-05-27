import Foundation

/// 格式化工具
struct Formatters {
    // MARK: - 日期格式化器
    
    /// 日期格式化器 - 短日期（年月日）
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    /// 日期格式化器 - 長日期（年月日 時分）
    static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
    
    /// 日期格式化器 - 完整日期（年月日 時分秒）
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter
    }()
    
    /// 日期格式化器 - 時間（時分）
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    /// 日期格式化器 - 月日
    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    /// 日期格式化器 - 年月
    static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM"
        return formatter
    }()
    
    /// 日期格式化器 - 相對日期
    static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - 數字格式化器
    
    /// 數字格式化器 - 小數點後兩位
    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// 數字格式化器 - 百分比
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    /// 數字格式化器 - 重量（公斤）
    static let weightFormatter: MassFormatter = {
        let formatter = MassFormatter()
        formatter.unitStyle = .medium
        return formatter
    }()
    
    /// 數字格式化器 - 長度（厘米）
    static let lengthFormatter: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.unitStyle = .medium
        return formatter
    }()
    
    // MARK: - 持續時間格式化器
    
    /// 格式化持續時間
    /// - Parameter seconds: 秒數
    /// - Returns: 格式化後的字符串
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)小時\(minutes)分鐘"
        } else {
            return "\(minutes)分鐘"
        }
    }
    
    /// 格式化短持續時間
    /// - Parameter seconds: 秒數
    /// - Returns: 格式化後的字符串
    static func formatShortDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - 文件大小格式化器
    
    /// 格式化文件大小
    /// - Parameter bytes: 字節數
    /// - Returns: 格式化後的字符串
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - 其他格式化器
    
    /// 格式化電話號碼
    /// - Parameter phoneNumber: 電話號碼
    /// - Returns: 格式化後的字符串
    static func formatPhoneNumber(_ phoneNumber: String) -> String {
        // 移除所有非數字字符
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // 台灣手機號碼格式：09xx-xxx-xxx
        if digits.count == 10 && digits.hasPrefix("09") {
            let firstPart = digits.prefix(4)
            let secondPart = digits.dropFirst(4).prefix(3)
            let thirdPart = digits.dropFirst(7)
            return "\(firstPart)-\(secondPart)-\(thirdPart)"
        }
        
        return phoneNumber
    }
    
    /// 格式化身高
    /// - Parameter cm: 厘米
    /// - Returns: 格式化後的字符串
    static func formatHeight(_ cm: Double) -> String {
        return lengthFormatter.string(fromValue: cm, unit: .centimeter)
    }
    
    /// 格式化體重
    /// - Parameter kg: 公斤
    /// - Returns: 格式化後的字符串
    static func formatWeight(_ kg: Double) -> String {
        return weightFormatter.string(fromValue: kg, unit: .kilogram)
    }
}
