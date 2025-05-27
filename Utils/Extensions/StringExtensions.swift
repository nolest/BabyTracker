import Foundation

/// 字符串擴展
extension String {
    /// 是否為空或只包含空白字符
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 首字母大寫
    var capitalized: String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    /// 駝峰式轉換
    var camelCased: String {
        guard !isEmpty else { return "" }
        
        let parts = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let first = parts.first!.lowercased()
        let rest = parts.dropFirst().map { $0.capitalized }
        
        return ([first] + rest).joined()
    }
    
    /// 蛇形式轉換
    var snakeCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.count)
        let snakeCase = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
        return snakeCase
    }
    
    /// 獲取子字符串
    /// - Parameters:
    ///   - from: 起始索引
    ///   - to: 結束索引
    /// - Returns: 子字符串
    func substring(from: Int, to: Int) -> String {
        let start = index(startIndex, offsetBy: max(0, from))
        let end = index(startIndex, offsetBy: min(count, to))
        return String(self[start..<end])
    }
    
    /// 獲取子字符串
    /// - Parameter from: 起始索引
    /// - Returns: 子字符串
    func substring(from: Int) -> String {
        return substring(from: from, to: count)
    }
    
    /// 獲取子字符串
    /// - Parameter to: 結束索引
    /// - Returns: 子字符串
    func substring(to: Int) -> String {
        return substring(from: 0, to: to)
    }
    
    /// 獲取字符串寬度
    /// - Parameter font: 字體
    /// - Returns: 寬度
    func width(withFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: attributes)
        return size.width
    }
    
    /// 獲取字符串高度
    /// - Parameters:
    ///   - font: 字體
    ///   - width: 寬度
    /// - Returns: 高度
    func height(withFont font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [NSAttributedString.Key.font: font],
            context: nil
        )
        return boundingBox.height
    }
    
    /// 是否包含字符串
    /// - Parameter string: 字符串
    /// - Returns: 是否包含
    func contains(_ string: String, caseSensitive: Bool = true) -> Bool {
        if caseSensitive {
            return self.range(of: string) != nil
        } else {
            return self.range(of: string, options: .caseInsensitive) != nil
        }
    }
    
    /// 是否匹配正則表達式
    /// - Parameter regex: 正則表達式
    /// - Returns: 是否匹配
    func matches(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
    
    /// 是否是有效的電子郵件
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return matches(regex: emailRegex)
    }
    
    /// 是否是有效的手機號碼（台灣）
    var isValidTaiwanPhoneNumber: Bool {
        let phoneRegex = "^09\\d{8}$"
        return matches(regex: phoneRegex)
    }
    
    /// 是否是有效的URL
    var isValidURL: Bool {
        return URL(string: self) != nil
    }
    
    /// 轉換為URL
    var url: URL? {
        return URL(string: self)
    }
    
    /// 轉換為Int
    var int: Int? {
        return Int(self)
    }
    
    /// 轉換為Double
    var double: Double? {
        return Double(self)
    }
    
    /// 轉換為Bool
    var bool: Bool? {
        let lowercased = self.lowercased()
        if lowercased == "true" || lowercased == "yes" || lowercased == "1" {
            return true
        } else if lowercased == "false" || lowercased == "no" || lowercased == "0" {
            return false
        }
        return nil
    }
    
    /// 轉換為Base64編碼
    var base64Encoded: String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    /// 從Base64解碼
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 轉換為MD5哈希
    var md5: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// 轉換為SHA256哈希
    var sha256: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// 為了支持哈希函數，需要導入CommonCrypto
import CommonCrypto
