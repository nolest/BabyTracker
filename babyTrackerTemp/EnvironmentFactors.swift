import Foundation

/// 環境因素
struct EnvironmentFactors: Codable {
    let lightLevel: Int?  // 0-100
    let noiseLevel: Int?  // 0-100
    let temperature: Double?  // 攝氏度
    let humidity: Double?  // 百分比
    
    init(lightLevel: Int? = nil,
         noiseLevel: Int? = nil,
         temperature: Double? = nil,
         humidity: Double? = nil) {
        self.lightLevel = lightLevel
        self.noiseLevel = noiseLevel
        self.temperature = temperature
        self.humidity = humidity
    }
}
