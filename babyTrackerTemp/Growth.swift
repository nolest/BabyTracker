import Foundation

/// 成長記錄模型
struct Growth: Codable, Identifiable {
    /// 唯一標識符
    let id: String
    
    /// 寶寶ID
    let babyId: String
    
    /// 記錄日期
    let date: Date
    
    /// 身高（厘米）
    let height: Double
    
    /// 體重（公斤）
    let weight: Double
    
    /// 頭圍（厘米）
    let headCircumference: Double
    
    /// 獲取百分位數據
    /// - Parameter baby: 寶寶信息
    /// - Returns: 百分位數據
    func getPercentileData(for baby: Baby) -> PercentileData {
        // 計算寶寶月齡
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: baby.birthDate, to: date)
        let ageInMonths = components.month ?? 0
        
        // 根據性別和月齡獲取WHO標準數據
        let standardData = getWHOStandardData(gender: baby.gender, ageInMonths: ageInMonths)
        
        // 計算身高百分位
        let heightPercentile = calculatePercentile(value: height, mean: standardData.heightMean, sd: standardData.heightSD)
        
        // 計算體重百分位
        let weightPercentile = calculatePercentile(value: weight, mean: standardData.weightMean, sd: standardData.weightSD)
        
        // 計算頭圍百分位
        let headCircumferencePercentile = calculatePercentile(value: headCircumference, mean: standardData.headCircumferenceMean, sd: standardData.headCircumferenceSD)
        
        return PercentileData(
            heightPercentile: heightPercentile,
            weightPercentile: weightPercentile,
            headCircumferencePercentile: headCircumferencePercentile
        )
    }
    
    /// 百分位數據
    struct PercentileData {
        /// 身高百分位
        let heightPercentile: Double
        
        /// 體重百分位
        let weightPercentile: Double
        
        /// 頭圍百分位
        let headCircumferencePercentile: Double
    }
    
    /// WHO標準數據
    private struct WHOStandardData {
        /// 身高均值
        let heightMean: Double
        
        /// 身高標準差
        let heightSD: Double
        
        /// 體重均值
        let weightMean: Double
        
        /// 體重標準差
        let weightSD: Double
        
        /// 頭圍均值
        let headCircumferenceMean: Double
        
        /// 頭圍標準差
        let headCircumferenceSD: Double
    }
    
    /// 獲取WHO標準數據
    /// - Parameters:
    ///   - gender: 性別
    ///   - ageInMonths: 月齡
    /// - Returns: WHO標準數據
    private func getWHOStandardData(gender: Baby.Gender, ageInMonths: Int) -> WHOStandardData {
        // 這裡應該根據WHO標準數據表查詢
        // 以下為示例數據，實際應用中應該使用完整的WHO數據
        
        // 男孩數據
        if gender == .male {
            switch ageInMonths {
            case 0:
                return WHOStandardData(heightMean: 49.9, heightSD: 1.9, weightMean: 3.3, weightSD: 0.5, headCircumferenceMean: 34.5, headCircumferenceSD: 1.1)
            case 1...3:
                return WHOStandardData(heightMean: 61.1, heightSD: 2.2, weightMean: 5.8, weightSD: 0.7, headCircumferenceMean: 40.1, headCircumferenceSD: 1.2)
            case 4...6:
                return WHOStandardData(heightMean: 67.6, heightSD: 2.5, weightMean: 7.9, weightSD: 0.9, headCircumferenceMean: 43.3, headCircumferenceSD: 1.3)
            case 7...12:
                return WHOStandardData(heightMean: 75.7, heightSD: 2.8, weightMean: 9.6, weightSD: 1.1, headCircumferenceMean: 46.1, headCircumferenceSD: 1.4)
            case 13...24:
                return WHOStandardData(heightMean: 86.8, heightSD: 3.2, weightMean: 12.2, weightSD: 1.5, headCircumferenceMean: 48.3, headCircumferenceSD: 1.5)
            default:
                return WHOStandardData(heightMean: 96.1, heightSD: 3.8, weightMean: 14.3, weightSD: 1.9, headCircumferenceMean: 49.5, headCircumferenceSD: 1.6)
            }
        }
        // 女孩數據
        else {
            switch ageInMonths {
            case 0:
                return WHOStandardData(heightMean: 49.1, heightSD: 1.8, weightMean: 3.2, weightSD: 0.4, headCircumferenceMean: 33.9, headCircumferenceSD: 1.0)
            case 1...3:
                return WHOStandardData(heightMean: 59.8, heightSD: 2.0, weightMean: 5.4, weightSD: 0.6, headCircumferenceMean: 39.3, headCircumferenceSD: 1.1)
            case 4...6:
                return WHOStandardData(heightMean: 65.7, heightSD: 2.3, weightMean: 7.3, weightSD: 0.8, headCircumferenceMean: 42.1, headCircumferenceSD: 1.2)
            case 7...12:
                return WHOStandardData(heightMean: 74.0, heightSD: 2.6, weightMean: 8.9, weightSD: 1.0, headCircumferenceMean: 44.9, headCircumferenceSD: 1.3)
            case 13...24:
                return WHOStandardData(heightMean: 85.7, heightSD: 3.0, weightMean: 11.5, weightSD: 1.4, headCircumferenceMean: 47.2, headCircumferenceSD: 1.4)
            default:
                return WHOStandardData(heightMean: 95.0, heightSD: 3.6, weightMean: 13.7, weightSD: 1.8, headCircumferenceMean: 48.5, headCircumferenceSD: 1.5)
            }
        }
    }
    
    /// 計算百分位
    /// - Parameters:
    ///   - value: 測量值
    ///   - mean: 均值
    ///   - sd: 標準差
    /// - Returns: 百分位（0-100）
    private func calculatePercentile(value: Double, mean: Double, sd: Double) -> Double {
        // 計算Z分數
        let zScore = (value - mean) / sd
        
        // 根據Z分數計算百分位
        // 使用正態分佈累積分佈函數
        let percentile = (1 + erf(zScore / sqrt(2))) / 2 * 100
        
        return min(max(percentile, 0), 100)
    }
    
    /// 誤差函數
    /// - Parameter x: 輸入值
    /// - Returns: 誤差函數值
    private func erf(_ x: Double) -> Double {
        // 誤差函數的近似計算
        // 來源: Abramowitz and Stegun, Handbook of Mathematical Functions
        
        let a1 =  0.254829592
        let a2 = -0.284496736
        let a3 =  1.421413741
        let a4 = -1.453152027
        let a5 =  1.061405429
        let p  =  0.3275911
        
        let sign = x < 0 ? -1 : 1
        let t = 1.0 / (1.0 + p * abs(x))
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x)
        
        return sign * y
    }
}
