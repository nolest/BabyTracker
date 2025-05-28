import Foundation

/// 寶寶信息模型
struct Baby: Codable, Identifiable {
    /// 唯一標識符
    let id: String
    
    /// 寶寶名稱
    var name: String
    
    /// 出生日期
    var birthDate: Date
    
    /// 性別
    var gender: Gender
    
    /// 照片URL
    var photoURL: URL?
    
    /// 性別枚舉
    enum Gender: String, Codable {
        /// 男
        case male
        
        /// 女
        case female
        
        /// 其他
        case other
    }
    
    /// 獲取寶寶年齡（月）
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }
    
    /// 獲取寶寶年齡描述
    var ageDescription: String {
        let months = ageInMonths
        
        if months < 1 {
            // 不足1個月，顯示天數
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: birthDate, to: Date())
            let days = components.day ?? 0
            return "\(days)天"
        } else if months < 24 {
            // 不足2歲，顯示月數
            return "\(months)個月"
        } else {
            // 2歲以上，顯示年數和月數
            let years = months / 12
            let remainingMonths = months % 12
            
            if remainingMonths == 0 {
                return "\(years)歲"
            } else {
                return "\(years)歲\(remainingMonths)個月"
            }
        }
    }
}
