import Foundation

/// 負責與Deepseek API的通信
class DeepseekAPIClient {
    // MARK: - 單例模式
    static let shared = DeepseekAPIClient()
    
    private init() {}
    
    // MARK: - 依賴
    private let apiKeyManager = APIKeyManager.shared
    
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
        // 獲取API Key
        let apiKey = apiKeyManager.getAPIKey()
        
        // 檢查API Key
        guard !apiKey.isEmpty else {
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

// MARK: - 請求和響應模型

/// Deepseek預測請求
struct DeepseekPredictionRequest: Codable {
    let sleepData: AnonymizedSleepData
    let routineData: AnonymizedRoutineData
}

/// Deepseek睡眠分析響應
struct DeepseekSleepAnalysisResponse: Codable {
    let id: String
    let analysisTime: Date
    let sleepPatterns: [SleepPattern]
    let recommendations: [Recommendation]
    let qualityScore: Int
    
    struct SleepPattern: Codable {
        let type: String
        let confidence: Double
        let description: String
    }
    
    struct Recommendation: Codable {
        let category: String
        let suggestion: String
        let priority: Int
    }
}

/// Deepseek作息分析響應
struct DeepseekRoutineAnalysisResponse: Codable {
    let id: String
    let analysisTime: Date
    let routinePatterns: [RoutinePattern]
    let recommendations: [Recommendation]
    let regularityScore: Int
    
    struct RoutinePattern: Codable {
        let type: String
        let confidence: Double
        let description: String
    }
    
    struct Recommendation: Codable {
        let category: String
        let suggestion: String
        let priority: Int
    }
}

/// Deepseek預測響應
struct DeepseekPredictionResponse: Codable {
    let id: String
    let predictionTime: Date
    let sleepPredictions: [SleepPrediction]
    let feedingPredictions: [FeedingPrediction]
    let confidenceScore: Int
    
    struct SleepPrediction: Codable {
        let predictedStartTime: Date
        let predictedDuration: TimeInterval
        let confidence: Double
    }
    
    struct FeedingPrediction: Codable {
        let predictedTime: Date
        let predictedType: String
        let confidence: Double
    }
}
