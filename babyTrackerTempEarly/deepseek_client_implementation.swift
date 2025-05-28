// DeepseekClient.swift
// 寶寶生活記錄專業版（Baby Tracker）
// Deepseek API客戶端實現

import Foundation

/// Deepseek API客戶端，負責處理與Deepseek API的通信
class DeepseekClient {
    // MARK: - 單例
    static let shared = DeepseekClient()
    private init() {}
    
    // MARK: - 常量
    private let baseURL = "https://api.deepseek.com"
    
    // MARK: - 睡眠模式分析
    
    /// 分析寶寶的睡眠模式
    /// - Parameters:
    ///   - data: 睡眠數據
    ///   - completion: 完成回調，返回分析結果或錯誤
    func analyzeSleepPattern(data: SleepData, completion: @escaping (Result<SleepAnalysis, Error>) -> Void) {
        // 檢查是否允許請求
        guard UsageLimiter.shared.canMakeRequest() else {
            let stats = UsageLimiter.shared.getUsageStatistics()
            completion(.failure(APIError.usageLimitExceeded(nextAllowedTime: stats.nextAllowedTime)))
            return
        }
        
        // 檢查緩存
        if let cachedResult = CacheManager.shared.getCachedSleepAnalysis(for: data.id) {
            completion(.success(cachedResult))
            return
        }
        
        // 準備請求
        let endpoint = "/v1/analyze/sleep"
        let apiKey = APIKeyManager.shared.getAPIKey()
        
        // 檢查API Key是否被限流
        if UsageLimiter.shared.isKeyRateLimited(apiKey) {
            completion(.failure(APIError.keyRateLimited))
            return
        }
        
        // 構建請求體
        let requestBody = prepareRequestBody(from: data)
        
        // 發送請求
        sendRequest(to: endpoint, with: requestBody, apiKey: apiKey) { result in
            switch result {
            case .success(let responseData):
                // 解析響應
                do {
                    let analysis = try self.parseSleepAnalysisResponse(responseData)
                    
                    // 緩存結果
                    CacheManager.shared.cacheSleepAnalysis(analysis, for: data.id)
                    
                    // 記錄使用
                    UsageLimiter.shared.recordUsage()
                    
                    completion(.success(analysis))
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                self.handleAPIError(error, apiKey: apiKey, completion: completion)
            }
        }
    }
    
    // MARK: - 作息模式分析
    
    /// 分析寶寶的作息模式
    /// - Parameters:
    ///   - data: 作息數據
    ///   - completion: 完成回調，返回分析結果或錯誤
    func analyzeRoutinePattern(data: RoutineData, completion: @escaping (Result<RoutineAnalysis, Error>) -> Void) {
        // 檢查是否允許請求
        guard UsageLimiter.shared.canMakeRequest() else {
            let stats = UsageLimiter.shared.getUsageStatistics()
            completion(.failure(APIError.usageLimitExceeded(nextAllowedTime: stats.nextAllowedTime)))
            return
        }
        
        // 檢查緩存
        if let cachedResult = CacheManager.shared.getCachedRoutineAnalysis(for: data.id) {
            completion(.success(cachedResult))
            return
        }
        
        // 準備請求
        let endpoint = "/v1/analyze/routine"
        let apiKey = APIKeyManager.shared.getAPIKey()
        
        // 檢查API Key是否被限流
        if UsageLimiter.shared.isKeyRateLimited(apiKey) {
            completion(.failure(APIError.keyRateLimited))
            return
        }
        
        // 構建請求體
        let requestBody = prepareRequestBody(from: data)
        
        // 發送請求
        sendRequest(to: endpoint, with: requestBody, apiKey: apiKey) { result in
            switch result {
            case .success(let responseData):
                // 解析響應
                do {
                    let analysis = try self.parseRoutineAnalysisResponse(responseData)
                    
                    // 緩存結果
                    CacheManager.shared.cacheRoutineAnalysis(analysis, for: data.id)
                    
                    // 記錄使用
                    UsageLimiter.shared.recordUsage()
                    
                    completion(.success(analysis))
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                self.handleAPIError(error, apiKey: apiKey, completion: completion)
            }
        }
    }
    
    // MARK: - 預測功能
    
    /// 預測寶寶的下一次睡眠和餵食時間
    /// - Parameters:
    ///   - data: 預測所需數據
    ///   - completion: 完成回調，返回預測結果或錯誤
    func predictNextEvents(data: PredictionData, completion: @escaping (Result<Prediction, Error>) -> Void) {
        // 檢查是否允許請求
        guard UsageLimiter.shared.canMakeRequest() else {
            let stats = UsageLimiter.shared.getUsageStatistics()
            completion(.failure(APIError.usageLimitExceeded(nextAllowedTime: stats.nextAllowedTime)))
            return
        }
        
        // 檢查緩存
        if let cachedResult = CacheManager.shared.getCachedPrediction(for: data.id) {
            completion(.success(cachedResult))
            return
        }
        
        // 準備請求
        let endpoint = "/v1/predict/events"
        let apiKey = APIKeyManager.shared.getAPIKey()
        
        // 檢查API Key是否被限流
        if UsageLimiter.shared.isKeyRateLimited(apiKey) {
            completion(.failure(APIError.keyRateLimited))
            return
        }
        
        // 構建請求體
        let requestBody = prepareRequestBody(from: data)
        
        // 發送請求
        sendRequest(to: endpoint, with: requestBody, apiKey: apiKey) { result in
            switch result {
            case .success(let responseData):
                // 解析響應
                do {
                    let prediction = try self.parsePredictionResponse(responseData)
                    
                    // 緩存結果
                    CacheManager.shared.cachePrediction(prediction, for: data.id)
                    
                    // 記錄使用
                    UsageLimiter.shared.recordUsage()
                    
                    completion(.success(prediction))
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                self.handleAPIError(error, apiKey: apiKey, completion: completion)
            }
        }
    }
    
    // MARK: - 輔助方法
    
    /// 發送API請求
    private func sendRequest(to endpoint: String, with body: Data, apiKey: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 添加設備指紋
        let deviceFingerprint = DeviceIdentifier.shared.getDeviceFingerprint()
        request.addValue(deviceFingerprint, forHTTPHeaderField: "X-Device-Fingerprint")
        
        // 添加時間戳和簽名
        let timestamp = String(Int(Date().timeIntervalSince1970))
        request.addValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        
        let signature = generateRequestSignature(timestamp: timestamp, deviceFingerprint: deviceFingerprint)
        request.addValue(signature, forHTTPHeaderField: "X-Signature")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            // 處理HTTP狀態碼
            switch httpResponse.statusCode {
            case 200...299:
                if let data = data {
                    completion(.success(data))
                } else {
                    completion(.failure(APIError.noData))
                }
                
            case 429:
                // 達到API限制
                completion(.failure(APIError.rateLimited))
                
            case 401:
                // 認證錯誤
                completion(.failure(APIError.authenticationFailed))
                
            default:
                completion(.failure(APIError.serverError(statusCode: httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
    
    /// 處理API錯誤
    private func handleAPIError<T>(_ error: Error, apiKey: String, completion: @escaping (Result<T, Error>) -> Void) {
        if case APIError.rateLimited = error {
            // 記錄限流事件
            UsageLimiter.shared.recordRateLimiting(forKey: apiKey)
        }
        
        completion(.failure(error))
    }
    
    /// 準備睡眠數據請求體
    private func prepareRequestBody(from data: SleepData) -> Data {
        // 匿名化數據
        let anonymizedData = anonymizeSleepData(data)
        
        // 轉換為JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(anonymizedData)
        } catch {
            // 如果編碼失敗，返回空數據
            return Data()
        }
    }
    
    /// 準備作息數據請求體
    private func prepareRequestBody(from data: RoutineData) -> Data {
        // 匿名化數據
        let anonymizedData = anonymizeRoutineData(data)
        
        // 轉換為JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(anonymizedData)
        } catch {
            // 如果編碼失敗，返回空數據
            return Data()
        }
    }
    
    /// 準備預測數據請求體
    private func prepareRequestBody(from data: PredictionData) -> Data {
        // 匿名化數據
        let anonymizedData = anonymizePredictionData(data)
        
        // 轉換為JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(anonymizedData)
        } catch {
            // 如果編碼失敗，返回空數據
            return Data()
        }
    }
    
    /// 匿名化睡眠數據
    private func anonymizeSleepData(_ data: SleepData) -> AnonymizedSleepData {
        // 移除個人識別信息
        return AnonymizedSleepData(
            id: generateAnonymousId(from: data.id),
            ageMonths: data.babyAgeMonths,
            startTime: data.startTime,
            endTime: data.endTime,
            interruptions: data.interruptions.map { anonymizeInterruption($0) },
            environmentFactors: data.environmentFactors
        )
    }
    
    /// 匿名化作息數據
    private func anonymizeRoutineData(_ data: RoutineData) -> AnonymizedRoutineData {
        // 移除個人識別信息
        return AnonymizedRoutineData(
            id: generateAnonymousId(from: data.id),
            ageMonths: data.babyAgeMonths,
            timeRange: data.timeRange,
            activities: data.activities.map { anonymizeActivity($0) }
        )
    }
    
    /// 匿名化預測數據
    private func anonymizePredictionData(_ data: PredictionData) -> AnonymizedPredictionData {
        // 移除個人識別信息
        return AnonymizedPredictionData(
            id: generateAnonymousId(from: data.id),
            ageMonths: data.babyAgeMonths,
            recentActivities: data.recentActivities.map { anonymizeActivity($0) },
            timeRange: data.timeRange
        )
    }
    
    /// 匿名化中斷
    private func anonymizeInterruption(_ interruption: SleepInterruption) -> AnonymizedSleepInterruption {
        return AnonymizedSleepInterruption(
            startTime: interruption.startTime,
            endTime: interruption.endTime,
            reason: interruption.reason
        )
    }
    
    /// 匿名化活動
    private func anonymizeActivity(_ activity: Activity) -> AnonymizedActivity {
        return AnonymizedActivity(
            type: activity.type,
            startTime: activity.startTime,
            endTime: activity.endTime,
            details: activity.details
        )
    }
    
    /// 生成匿名ID
    private func generateAnonymousId(from originalId: String) -> String {
        // 使用哈希函數生成匿名ID
        return "anon_" + originalId.sha256().prefix(10).lowercased()
    }
    
    /// 解析睡眠分析響應
    private func parseSleepAnalysisResponse(_ data: Data) throws -> SleepAnalysis {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // 這裡應該根據實際的API響應格式進行解析
        // 以下是模擬實現
        
        // 解析JSON
        let response = try decoder.decode(SleepAnalysisResponse.self, from: data)
        
        // 轉換為模型
        return SleepAnalysis(
            id: response.id,
            quality: response.quality,
            duration: response.duration,
            cycles: response.cycles,
            timestamp: Date(),
            deepSleepPercentage: response.sleepStages?.deepSleep,
            remSleepPercentage: response.sleepStages?.remSleep,
            lightSleepPercentage: response.sleepStages?.lightSleep,
            environmentImpact: response.environmentImpact.map {
                SleepAnalysis.EnvironmentImpact(
                    lightImpact: $0.light,
                    noiseImpact: $0.noise,
                    temperatureImpact: $0.temperature
                )
            },
            recommendations: response.recommendations
        )
    }
    
    /// 解析作息分析響應
    private func parseRoutineAnalysisResponse(_ data: Data) throws -> RoutineAnalysis {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // 這裡應該根據實際的API響應格式進行解析
        // 以下是模擬實現
        
        // 解析JSON
        let response = try decoder.decode(RoutineAnalysisResponse.self, from: data)
        
        // 轉換為模型
        return RoutineAnalysis(
            id: response.id,
            regularityScore: response.regularityScore,
            typicalPatterns: response.patterns.map {
                RoutineAnalysis.Pattern(
                    name: $0.name,
                    frequency: $0.frequency,
                    activities: $0.activities
                )
            },
            timeDistribution: response.timeDistribution.map {
                RoutineAnalysis.TimeBlock(
                    startHour: $0.startHour,
                    endHour: $0.endHour,
                    activities: $0.activities
                )
            },
            timestamp: Date(),
            recommendations: response.recommendations
        )
    }
    
    /// 解析預測響應
    private func parsePredictionResponse(_ data: Data) throws -> Prediction {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // 這裡應該根據實際的API響應格式進行解析
        // 以下是模擬實現
        
        // 解析JSON
        let response = try decoder.decode(PredictionResponse.self, from: data)
        
        // 轉換為模型
        return Prediction(
            id: response.id,
            nextSleepTime: response.nextSleep?.time,
            expectedSleepDuration: response.nextSleep?.duration,
            nextFeedingTime: response.nextFeeding?.time,
            confidence: response.confidence,
            timestamp: Date(),
            factors: response.factors
        )
    }
}

// MARK: - API錯誤類型

/// API錯誤類型
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case rateLimited
    case keyRateLimited
    case usageLimitExceeded(nextAllowedTime: Date?)
    case authenticationFailed
    case serverError(statusCode: Int)
    case parsingError
}

// MARK: - 請求模型

/// 睡眠數據模型
struct SleepData {
    let id: String
    let babyId: String
    let babyName: String
    let babyAgeMonths: Int
    let startTime: Date
    let endTime: Date
    let interruptions: [SleepInterruption]
    let environmentFactors: EnvironmentFactors
}

/// 匿名化的睡眠數據模型
struct AnonymizedSleepData: Codable {
    let id: String
    let ageMonths: Int
    let
(Content truncated due to size limit. Use line ranges to read in chunks)