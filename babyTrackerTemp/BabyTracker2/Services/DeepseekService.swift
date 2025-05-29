import Foundation
import Combine
import UIKit

class DeepseekService {
    static let shared = DeepseekService()
    
    // API Keys 分段存儲，運行時動態組合
    private let apiKeyParts = [
        ["sk-ae", "fd76", "9031e0"],
        ["449", "8868", "14d54"],
        ["03b", "028", "f3"]
    ]
    
    // 請求頻率限制
    private let hourlyLimit = 10
    private let dailyLimit = 30
    
    // 請求計數器
    private var hourlyRequestCount = 0
    private var dailyRequestCount = 0
    private var lastHourReset = Date()
    private var lastDayReset = Date()
    
    // 緩存
    private var analysisCache = [String: Any]()
    
    private init() {
        // 重置計數器
        resetCountersIfNeeded()
    }
    
    // 根據設備ID選擇API Key
    private func getApiKey() -> String {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let hash = deviceId.hash
        let index = abs(hash) % apiKeyParts.count
        return apiKeyParts[index].joined()
    }
    
    // 重置計數器
    private func resetCountersIfNeeded() {
        let now = Date()
        
        // 檢查小時重置
        if now.timeIntervalSince(lastHourReset) >= 3600 {
            hourlyRequestCount = 0
            lastHourReset = now
        }
        
        // 檢查日重置
        if now.timeIntervalSince(lastDayReset) >= 86400 {
            dailyRequestCount = 0
            lastDayReset = now
        }
    }
    
    // 檢查是否可以發送請求
    private func canMakeRequest() -> Bool {
        resetCountersIfNeeded()
        return hourlyRequestCount < hourlyLimit && dailyRequestCount < dailyLimit
    }
    
    // 增加請求計數
    private func incrementRequestCount() {
        hourlyRequestCount += 1
        dailyRequestCount += 1
    }
    
    // 生成緩存鍵
    private func cacheKey(for analysisType: String, data: [String: Any]) -> String {
        return "\(analysisType)_\(data.description.hash)"
    }
    
    // 檢查緩存
    private func checkCache(for key: String) -> Any? {
        return analysisCache[key]
    }
    
    // 保存到緩存
    private func saveToCache(key: String, result: Any) {
        analysisCache[key] = result
    }
    
    // 發送API請求
    func sendRequest(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 檢查頻率限制
        guard canMakeRequest() else {
            completion(.failure(NSError(domain: "com.babytracker.deepseek", code: 429, userInfo: [NSLocalizedDescriptionKey: "Request limit exceeded. Please try again later."])))
            return
        }
        
        // 構建請求
        let apiKey = getApiKey()
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // 發送請求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.babytracker.deepseek", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // 增加請求計數
                    self.incrementRequestCount()
                    
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "com.babytracker.deepseek", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // 分析睡眠模式
    func analyzeSleepPattern(sleepData: [SleepActivity], completion: @escaping (Result<String, Error>) -> Void) {
        // 構建數據摘要
        let dataDict = sleepData.map { activity -> [String: Any] in
            return [
                "startTime": ISO8601DateFormatter().string(from: activity.startTime!),
                "endTime": activity.endTime != nil ? ISO8601DateFormatter().string(from: activity.endTime!) : "",
                "duration": activity.duration,
                "quality": activity.sleepQuality ?? "unknown"
            ]
        }
        
        // 檢查緩存
        let key = cacheKey(for: "sleep_pattern", data: ["data": dataDict])
        if let cachedResult = checkCache(for: key) as? String {
            completion(.success(cachedResult))
            return
        }
        
        // 構建提示詞
        let prompt = """
        分析以下睡眠數據，識別模式和規律，並提供改善建議：
        \(dataDict)
        
        請提供：
        1. 睡眠模式分析（規律性、持續時間、質量）
        2. 可能的問題識別
        3. 改善建議
        4. 預測未來幾天的最佳睡眠時間
        """
        
        // 發送請求
        sendRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                // 保存到緩存
                self.saveToCache(key: key, result: response)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 分析餵食模式
    func analyzeFeedingPattern(feedingData: [FeedingActivity], completion: @escaping (Result<String, Error>) -> Void) {
        // 構建數據摘要
        let dataDict = feedingData.map { activity -> [String: Any] in
            return [
                "startTime": ISO8601DateFormatter().string(from: activity.startTime!),
                "feedingType": activity.feedingType ?? "",
                "amount": activity.amount,
                "duration": activity.duration
            ]
        }
        
        // 檢查緩存
        let key = cacheKey(for: "feeding_pattern", data: ["data": dataDict])
        if let cachedResult = checkCache(for: key) as? String {
            completion(.success(cachedResult))
            return
        }
        
        // 構建提示詞
        let prompt = """
        分析以下餵食數據，識別模式和規律，並提供改善建議：
        \(dataDict)
        
        請提供：
        1. 餵食模式分析（頻率、數量、類型分佈）
        2. 可能的問題識別
        3. 改善建議
        4. 預測未來幾天的最佳餵食時間和數量
        """
        
        // 發送請求
        sendRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                // 保存到緩存
                self.saveToCache(key: key, result: response)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 分析成長數據
    func analyzeGrowthData(growthData: [GrowthRecord], completion: @escaping (Result<String, Error>) -> Void) {
        // 構建數據摘要
        let dataDict = growthData.map { record -> [String: Any] in
            return [
                "date": ISO8601DateFormatter().string(from: record.date!),
                "weight": record.weight,
                "height": record.height,
                "headCircumference": record.headCircumference ?? 0
            ]
        }
        
        // 檢查緩存
        let key = cacheKey(for: "growth_data", data: ["data": dataDict])
        if let cachedResult = checkCache(for: key) as? String {
            completion(.success(cachedResult))
            return
        }
        
        // 構建提示詞
        let prompt = """
        分析以下嬰兒成長數據，與WHO標準曲線比較，並提供建議：
        \(dataDict)
        
        請提供：
        1. 成長曲線分析（與WHO標準比較）
        2. 可能的問題識別
        3. 營養和活動建議
        4. 預測未來成長趨勢
        """
        
        // 發送請求
        sendRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                // 保存到緩存
                self.saveToCache(key: key, result: response)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 生成綜合建議
    func generateComprehensiveSuggestions(baby: Baby, completion: @escaping (Result<String, Error>) -> Void) {
        // 獲取最近的活動數據
        let dataController = DataController.shared
        let recentActivities = dataController.getRecentActivities(for: baby, limit: 50)
        
        // 構建數據摘要
        var dataDict: [String: Any] = [
            "babyName": baby.name ?? "",
            "babyAge": Calendar.current.dateComponents([.day], from: baby.birthDate!, to: Date()).day ?? 0,
            "recentActivities": recentActivities.map { activity -> [String: Any] in
                return [
                    "type": activity.type ?? "",
                    "startTime": ISO8601DateFormatter().string(from: activity.startTime!),
                    "duration": activity.duration
                ]
            }
        ]
        
        // 檢查緩存
        let key = cacheKey(for: "comprehensive_suggestions", data: dataDict)
        if let cachedResult = checkCache(for: key) as? String {
            completion(.success(cachedResult))
            return
        }
        
        // 構建提示詞
        let prompt = """
        基於以下嬰兒數據，生成綜合育兒建議：
        \(dataDict)
        
        請提供：
        1. 整體發展評估
        2. 睡眠、餵食和活動建議
        3. 未來幾天的最佳作息安排
        4. 可能需要注意的發展里程碑
        5. 父母照顧技巧建議
        """
        
        // 發送請求
        sendRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                // 保存到緩存
                self.saveToCache(key: key, result: response)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
