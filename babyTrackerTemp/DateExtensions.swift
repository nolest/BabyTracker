import Foundation

/// 日期擴展
extension Date {
    /// 格式化日期
    /// - Parameter format: 格式
    /// - Returns: 格式化後的字符串
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// 獲取當天開始時間
    /// - Returns: 當天開始時間
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// 獲取當天結束時間
    /// - Returns: 當天結束時間
    func endOfDay() -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay())!
    }
    
    /// 獲取當週開始時間
    /// - Returns: 當週開始時間
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }
    
    /// 獲取當週結束時間
    /// - Returns: 當週結束時間
    func endOfWeek() -> Date {
        var components = DateComponents()
        components.day = 7
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek())!
    }
    
    /// 獲取當月開始時間
    /// - Returns: 當月開始時間
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    /// 獲取當月結束時間
    /// - Returns: 當月結束時間
    func endOfMonth() -> Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth())!
    }
    
    /// 添加天數
    /// - Parameter days: 天數
    /// - Returns: 新日期
    func addDays(_ days: Int) -> Date {
        var components = DateComponents()
        components.day = days
        return Calendar.current.date(byAdding: components, to: self)!
    }
    
    /// 添加小時
    /// - Parameter hours: 小時
    /// - Returns: 新日期
    func addHours(_ hours: Int) -> Date {
        var components = DateComponents()
        components.hour = hours
        return Calendar.current.date(byAdding: components, to: self)!
    }
    
    /// 添加分鐘
    /// - Parameter minutes: 分鐘
    /// - Returns: 新日期
    func addMinutes(_ minutes: Int) -> Date {
        var components = DateComponents()
        components.minute = minutes
        return Calendar.current.date(byAdding: components, to: self)!
    }
    
    /// 與另一個日期的天數差
    /// - Parameter date: 另一個日期
    /// - Returns: 天數差
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }
    
    /// 是否是同一天
    /// - Parameter date: 另一個日期
    /// - Returns: 是否是同一天
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    /// 是否是今天
    /// - Returns: 是否是今天
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    /// - Returns: 是否是昨天
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// 是否是明天
    /// - Returns: 是否是明天
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    /// 獲取年份
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// 獲取月份
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    /// 獲取日
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    /// 獲取小時
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    /// 獲取分鐘
    var minute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    /// 獲取秒
    var second: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    /// 獲取星期幾
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    /// 獲取相對時間描述
    var relativeTimeDescription: String {
        let now = Date()
        
        if self.isSameDay(as: now) {
            let components = Calendar.current.dateComponents([.hour, .minute], from: self, to: now)
            
            if let hour = components.hour, hour > 0 {
                return "\(hour)小時前"
            } else if let minute = components.minute, minute > 0 {
                return "\(minute)分鐘前"
            } else {
                return "剛剛"
            }
        } else if self.isSameDay(as: now.addDays(-1)) {
            return "昨天 \(self.format("HH:mm"))"
        } else if self.isSameDay(as: now.addDays(-2)) {
            return "前天 \(self.format("HH:mm"))"
        } else if self.daysBetween(now) < -7 {
            return self.format("MM月dd日 HH:mm")
        } else {
            let weekdays = ["週日", "週一", "週二", "週三", "週四", "週五", "週六"]
            let weekday = weekdays[self.weekday - 1]
            return "\(weekday) \(self.format("HH:mm"))"
        }
    }
}
