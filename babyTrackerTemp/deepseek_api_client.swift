// DeepseekAPIClient.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：Deepseek API整合
// Deepseek API 客戶端

import Foundation

/// 負責與Deepseek API的通信
class DeepseekAPIClient {
    // MARK: - 單例模式
    static let shared = DeepseekAPIClient()
    
    private init() {}
    
    // MARK: - 常量
    
    private enum APIEndpoints {
        static let baseURL = "https://api.deepseek.com"
        static let sleepAnalysis = "/v1/baby/sleep/analyze"
        static let routineAnalysis = "/v1/baby/routine/analyze"
        static let predictionGenerate = "/v1/baby/prediction/generate"
    }
    
    private enum HTTPMethod {
        static let post = "POST"
        static let get = "GET"
    }
    
    // MARK: - API錯誤
    
    enum APIError: Error {
        case invalidURL
        case invalidAPIKey
        case networkError(Error)
        case serverError(Int, String)
        case decodingError(Error)
        case noData
        case rateLimitExceeded
        case timeout
        case unknown
    }
    
    // MARK: - 公開方法
    
    /// 分析睡眠數據
    /// - Parameter data: 匿名化的睡眠數據
    /// - Returns: 分析結果或錯誤
    func analyzeSleep(data: AnonymizedSleepData) async -> Result<DeepseekSleepAnalysisResponse, APIError> {
        return await sendRequest(
            endpoint: APIEndpoints.sleepAnalysis,
            body: data
        )
    }
    
    /// 分析作息數據
    /// - Parameter data: 匿名化的作息數據
    /// - Returns: 分析結果或錯誤
    func analyzeRoutine(data: AnonymizedRoutineData) async -> Result<DeepseekRoutineAnalysisResponse, APIError> {
        return await sendRequest(
            endpoint: APIEndpoints.routineAnalysis,
            body: data
        )
    }
    
    /// 生成預測
    /// - Parameters:
    ///   - sleepData: 匿名化的睡眠數據
    ///   - routineData: 匿名化的作息數據
    /// - Returns: 預測結果或錯誤
    func generatePrediction(
        sleepData: AnonymizedSleepData,
        routineData: AnonymizedRoutineData
    ) async -> Result<DeepseekPredictionResponse, APIError> {
        // 創建組合請求數據
        let combinedData = DeepseekPredictionRequest(
            sleepData: sleepData,
            routineData: routineData
        )
        
        return await sendRequest(
            endpoint: APIEndpoints.predictionGenerate,
            body: combinedData
        )
    }
    
    // MARK: - 私有方法
    
    /// 發送API請求
    /// - Parameters:
    ///   - endpoint: API端點
    ///   - body: 請求體
    /// - Returns: 響應結果或錯誤
    private func sendRequest<T: Encodable, U: Decodable>(
        endpoint: String,
        body: T
    ) async -> Result<U, APIError> {
        // 檢查API Key
        guard let apiKey = UserSettings.shared.deepseekAPIKey, !apiKey.isEmpty else {
            return .failure(.invalidAPIKey)
        }
        
        // 創建URL
        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            return .failure(.invalidURL)
        }
        
        // 創建請求
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 設置超時
        request.timeoutInterval = 30
        
        do {
            // 編碼請求體
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
            
            // 發送請求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 檢查HTTP響應
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknown)
            }
            
            // 處理HTTP狀態碼
            switch httpResponse.statusCode {
            case 200...299:
                // 成功
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(U.self, from: data)
                    return .success(result)
                } catch {
                    return .failure(.decodingError(error))
                }
                
            case 401:
                // 未授權（無效的API Key）
                return .failure(.invalidAPIKey)
                
            case 429:
                // 超出速率限制
                return .failure(.rateLimitExceeded)
                
            default:
                // 其他錯誤
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(.serverError(httpResponse.statusCode, errorMessage))
            }
            
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout)
        } catch {
            return .failure(.networkError(error))
        }
    }
}

// MARK: - API請求/響應模型

/// Deepseek預測請求
struct DeepseekPredictionRequest: Codable {
    let sleepData: AnonymizedSleepData
    let routineData: AnonymizedRoutineData
}

/// Deepseek睡眠分析響應
struct DeepseekSleepAnalysisResponse: Codable {
    let analysisId: String
    let sleepPatternType: String
    let regularityScore: Int
    let averageSleepDuration: Double
    let sleepQualityScore: Int
    let environmentalFactorImpact: EnvironmentalFactorImpact
    let sleepTrend: String
    let recommendations: [String]
    let confidenceScore: Double
}

/// 環境因素影響
struct EnvironmentalFactorImpact: Codable {
    let light: FactorImpact
    let noise: FactorImpact
    let temperature: FactorImpact
    let humidity: FactorImpact
}

/// 因素影響
struct FactorImpact: Codable {
    let impactLevel: String
    let correlation: Double
    let recommendation: String?
}

/// Deepseek作息分析響應
struct DeepseekRoutineAnalysisResponse: Codable {
    let analysisId: String
    let routineRegularityScore: Int
    let typicalPatterns: [TypicalPattern]
    let activityDistribution: [ActivityDistribution]
    let routineTrend: String
    let recommendations: [String]
    let confidenceScore: Double
}

/// 典型模式
struct TypicalPattern: Codable {
    let patternName: String
    let activities: [String]
    let averageDuration: Double
    let frequency: Double
}

/// 活動分佈
struct ActivityDistribution: Codable {
    let activityType: String
    let percentage: Double
    let averageDuration: Double
    let preferredTimeRanges: [TimeRange]
}

/// 時間範圍
struct TimeRange: Codable {
    let startMinutes: Int
    let endMinutes: Int
    let frequency: Double
}

/// Deepseek預測響應
struct DeepseekPredictionResponse: Codable {
    let predictionId: String
    let nextSleep: NextSleepPrediction?
    let nextFeeding: NextFeedingPrediction?
    let nextActivity: NextActivityPrediction?
    let confidenceScore: Double
    let recommendations: [String]
}

/// 下次睡眠預測
struct NextSleepPrediction: Codable {
    let earliestStartMinutes: Int
    let latestStartMinutes: Int
    let expectedDurationMinutes: Int
    let durationVarianceMinutes: Int
    let confidence: Double
}

/// 下次餵食預測
struct NextFeedingPrediction: Codable {
    let earliestStartMinutes: Int
    let latestStartMinutes: Int
    let expectedDurationMinutes: Int
    let confidence: Double
}

/// 下次活動預測
struct NextActivityPrediction: Codable {
    let activityType: String
    let earliestStartMinutes: Int
    let latestStartMinutes: Int
    let confidence: Double
}
