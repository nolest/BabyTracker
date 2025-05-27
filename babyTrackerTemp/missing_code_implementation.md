# 寶寶生活記錄專業版（Baby Tracker）- 缺失代碼補充

本文件提供了「寶寶生活記錄專業版（Baby Tracker）」iOS應用中缺失的必要代碼定義，包括數據模型、錯誤類型、Repository接口等，以確保代碼的完整性和可組裝性。

## 1. 核心數據模型

### 1.1 活動類型枚舉

```swift
// ActivityType.swift

import Foundation

/// 活動類型枚舉
enum ActivityType: String, Codable, CaseIterable {
    case sleep = "sleep"           // 睡眠
    case feeding = "feeding"       // 餵食
    case diaper = "diaper"         // 換尿布
    case bath = "bath"             // 洗澡
    case play = "play"             // 玩耍
    case tummyTime = "tummyTime"   // 趴著時間
    case outdoors = "outdoors"     // 戶外活動
    case medication = "medication" // 用藥
    case other = "other"           // 其他
    
    var localizedName: String {
        switch self {
        case .sleep:
            return NSLocalizedString("睡眠", comment: "Sleep activity type")
        case .feeding:
            return NSLocalizedString("餵食", comment: "Feeding activity type")
        case .diaper:
            return NSLocalizedString("換尿布", comment: "Diaper activity type")
        case .bath:
            return NSLocalizedString("洗澡", comment: "Bath activity type")
        case .play:
            return NSLocalizedString("玩耍", comment: "Play activity type")
        case .tummyTime:
            return NSLocalizedString("趴著時間", comment: "Tummy time activity type")
        case .outdoors:
            return NSLocalizedString("戶外活動", comment: "Outdoors activity type")
        case .medication:
            return NSLocalizedString("用藥", comment: "Medication activity type")
        case .other:
            return NSLocalizedString("其他", comment: "Other activity type")
        }
    }
    
    var icon: String {
        switch self {
        case .sleep:
            return "moon.zzz.fill"
        case .feeding:
            return "bottle.fill"
        case .diaper:
            return "heart.fill"
        case .bath:
            return "drop.fill"
        case .play:
            return "gamecontroller.fill"
        case .tummyTime:
            return "figure.walk"
        case .outdoors:
            return "sun.max.fill"
        case .medication:
            return "pills.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}
```

### 1.2 餵食類型枚舉

```swift
// FeedingType.swift

import Foundation

/// 餵食類型枚舉
enum FeedingType: String, Codable, CaseIterable {
    case breastfeeding = "breastfeeding"       // 母乳餵食
    case bottleBreastMilk = "bottleBreastMilk" // 瓶餵母乳
    case formula = "formula"                   // 配方奶
    case solidFood = "solidFood"               // 固體食物
    case water = "water"                       // 水
    case other = "other"                       // 其他
    
    var localizedName: String {
        switch self {
        case .breastfeeding:
            return NSLocalizedString("母乳餵食", comment: "Breastfeeding type")
        case .bottleBreastMilk:
            return NSLocalizedString("瓶餵母乳", comment: "Bottle breast milk type")
        case .formula:
            return NSLocalizedString("配方奶", comment: "Formula type")
        case .solidFood:
            return NSLocalizedString("固體食物", comment: "Solid food type")
        case .water:
            return NSLocalizedString("水", comment: "Water type")
        case .other:
            return NSLocalizedString("其他", comment: "Other feeding type")
        }
    }
    
    var icon: String {
        switch self {
        case .breastfeeding:
            return "heart.fill"
        case .bottleBreastMilk:
            return "drop.fill"
        case .formula:
            return "bottle.fill"
        case .solidFood:
            return "fork.knife"
        case .water:
            return "drop"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}
```

### 1.3 睡眠記錄模型

```swift
// SleepRecord.swift

import Foundation

/// 睡眠記錄模型
struct SleepRecord: Identifiable, Codable {
    let id: String
    let babyId: String
    let startTime: Date
    let endTime: Date
    let quality: Int?  // 0-100
    let environmentFactors: EnvironmentFactors?
    let interruptions: [SleepInterruption]
    let notes: String?
    
    init(id: String = UUID().uuidString,
         babyId: String,
         startTime: Date,
         endTime: Date,
         quality: Int? = nil,
         environmentFactors: EnvironmentFactors? = nil,
         interruptions: [SleepInterruption] = [],
         notes: String? = nil) {
        self.id = id
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
        self.environmentFactors = environmentFactors
        self.interruptions = interruptions
        self.notes = notes
    }
    
    /// 睡眠持續時間（秒）
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 睡眠持續時間（小時）
    var durationHours: Double {
        return duration / 3600
    }
    
    /// 是否為夜間睡眠
    var isNightSleep: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        return hour >= 19 || hour < 7
    }
}

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

/// 睡眠中斷
struct SleepInterruption: Codable {
    let duration: TimeInterval  // 中斷持續時間（秒）
    let reason: String?  // 中斷原因
    
    init(duration: TimeInterval, reason: String? = nil) {
        self.duration = duration
        self.reason = reason
    }
}
```

### 1.4 活動記錄模型

```swift
// Activity.swift

import Foundation

/// 活動記錄模型
struct Activity: Identifiable, Codable {
    let id: String
    let babyId: String
    let type: ActivityType
    let startTime: Date
    let endTime: Date?
    let notes: String?
    
    init(id: String = UUID().uuidString,
         babyId: String,
         type: ActivityType,
         startTime: Date,
         endTime: Date? = nil,
         notes: String? = nil) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
    
    /// 活動持續時間（秒），如果沒有結束時間則返回nil
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

/// 活動記錄（用於分析）
struct ActivityRecord {
    let id: String
    let type: ActivityType
    let startTime: Date
    let endTime: Date
    let notes: String?
    
    init(id: String,
         type: ActivityType,
         startTime: Date,
         endTime: Date,
         notes: String? = nil) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
}
```

### 1.5 餵食記錄模型

```swift
// FeedingRecord.swift

import Foundation

/// 餵食記錄模型
struct FeedingRecord: Identifiable, Codable {
    let id: String
    let babyId: String
    let startTime: Date
    let endTime: Date?
    let type: FeedingType
    let amount: Double?  // 毫升或克
    let notes: String?
    
    init(id: String = UUID().uuidString,
         babyId: String,
         startTime: Date,
         endTime: Date? = nil,
         type: FeedingType,
         amount: Double? = nil,
         notes: String? = nil) {
        self.id = id
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.amount = amount
        self.notes = notes
    }
    
    /// 餵食持續時間（秒），如果沒有結束時間則返回nil
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}
```

## 2. 錯誤類型定義

### 2.1 雲端錯誤

```swift
// CloudError.swift

import Foundation

/// 雲端服務錯誤
enum CloudError: Error {
    case cloudAnalysisDisabled  // 雲端分析已禁用
    case insufficientData       // 數據不足
    case invalidAPIKey          // 無效的API Key
    case networkError           // 網絡錯誤
    case serverError            // 服務器錯誤
    case rateLimitExceeded      // 超出速率限制
    case timeout                // 請求超時
    case unknownError           // 未知錯誤
}

extension CloudError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cloudAnalysisDisabled:
            return NSLocalizedString("雲端分析功能已禁用", comment: "")
        case .insufficientData:
            return NSLocalizedString("數據不足，無法進行分析", comment: "")
        case .invalidAPIKey:
            return NSLocalizedString("API密鑰無效", comment: "")
        case .networkError:
            return NSLocalizedString("網絡連接錯誤", comment: "")
        case .serverError:
            return NSLocalizedString("服務器錯誤", comment: "")
        case .rateLimitExceeded:
            return NSLocalizedString("已超出API使用限制，請稍後再試", comment: "")
        case .timeout:
            return NSLocalizedString("請求超時", comment: "")
        case .unknownError:
            return NSLocalizedString("發生未知錯誤", comment: "")
        }
    }
}
```

### 2.2 分析錯誤

```swift
// AnalysisError.swift

import Foundation

/// 分析錯誤
enum AnalysisError: Error {
    case insufficientData       // 數據不足
    case invalidDateRange       // 無效的日期範圍
    case processingError        // 處理錯誤
    case repositoryError(Error) // 倉庫錯誤
}

extension AnalysisError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return NSLocalizedString("數據不足，無法進行分析", comment: "")
        case .invalidDateRange:
            return NSLocalizedString("無效的日期範圍", comment: "")
        case .processingError:
            return NSLocalizedString("分析處理過程中發生錯誤", comment: "")
        case .repositoryError(let error):
            return NSLocalizedString("數據獲取錯誤: \(error.localizedDescription)", comment: "")
        }
    }
}
```

## 3. Repository接口定義

### 3.1 睡眠記錄倉庫

```swift
// SleepRecordRepository.swift

import Foundation

/// 睡眠記錄倉庫協議
protocol SleepRecordRepositoryProtocol {
    /// 獲取指定寶寶在特定時間範圍內的睡眠記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 睡眠記錄列表或錯誤
    func getSleepRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[SleepRecord], Error>
    
    /// 保存睡眠記錄
    /// - Parameter record: 睡眠記錄
    /// - Returns: 成功或錯誤
    func saveSleepRecord(_ record: SleepRecord) async -> Result<Void, Error>
    
    /// 刪除睡眠記錄
    /// - Parameter id: 記錄ID
    /// - Returns: 成功或錯誤
    func deleteSleepRecord(id: String) async -> Result<Void, Error>
}

/// 睡眠記錄倉庫實現
class SleepRecordRepository: SleepRecordRepositoryProtocol {
    // MARK: - 單例
    static let shared = SleepRecordRepository()
    
    private init() {}
    
    // MARK: - 實現方法
    
    func getSleepRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[SleepRecord], Error> {
        // 在實際應用中，這裡會從CoreData或其他數據源獲取數據
        // 這裡提供一個模擬實現
        return .success([])
    }
    
    func saveSleepRecord(_ record: SleepRecord) async -> Result<Void, Error> {
        // 在實際應用中，這裡會保存到CoreData或其他數據源
        // 這裡提供一個模擬實現
        return .success(())
    }
    
    func deleteSleepRecord(id: String) async -> Result<Void, Error> {
        // 在實際應用中，這裡會從CoreData或其他數據源刪除
        // 這裡提供一個模擬實現
        return .success(())
    }
}
```

### 3.2 活動倉庫

```swift
// ActivityRepository.swift

import Foundation

/// 活動倉庫協議
protocol ActivityRepositoryProtocol {
    /// 獲取指定寶寶在特定時間範圍內的活動記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 活動記錄列表或錯誤
    func getActivities(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[Activity], Error>
    
    /// 保存活動記錄
    /// - Parameter activity: 活動記錄
    /// - Returns: 成功或錯誤
    func saveActivity(_ activity: Activity) async -> Result<Void, Error>
    
    /// 刪除活動記錄
    /// - Parameter id: 記錄ID
    /// - Returns: 成功或錯誤
    func deleteActivity(id: String) async -> Result<Void, Error>
}

/// 活動倉庫實現
class ActivityRepository: ActivityRepositoryProtocol {
    // MARK: - 單例
    static let shared = ActivityRepository()
    
    private init() {}
    
    // MARK: - 實現方法
    
    func getActivities(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[Activity], Error> {
        // 在實際應用中，這裡會從CoreData或其他數據源獲取數據
        // 這裡提供一個模擬實現
        return .success([])
    }
    
    func saveActivity(_ activity: Activity) async -> Result<Void, Error> {
        // 在實際應用中，這裡會保存到CoreData或其他數據源
        // 這裡提供一個模擬實現
        return .success(())
    }
    
    func deleteActivity(id: String) async -> Result<Void, Error> {
        // 在實際應用中，這裡會從CoreData或其他數據源刪除
        // 這裡提供一個模擬實現
        return .success(())
    }
}
```

### 3.3 餵食記錄倉庫

```swift
// FeedingRepository.swift

import Foundation

/// 餵食記錄倉庫協議
protocol FeedingRepositoryProtocol {
    /// 獲取指定寶寶在特定時間範圍內的餵食記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 餵食記錄列表或錯誤
    func getFeedingRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[FeedingRecord], Error>
    
    /// 保存餵食記錄
    /// - Parameter record: 餵食記錄
    /// - Returns: 成功或錯誤
    func saveFeedingRecord(_ record: FeedingRecord) async -> Result<Void, Error>
    
    /// 刪除餵食記錄
    /// - Parameter id: 記錄ID
    /// - Returns: 成功或錯誤
    func deleteFeedingRecord(id: String) async -> Result<Void, Error>
}

/// 餵食記錄倉庫實現
class FeedingRepository: FeedingRepositoryProtocol {
    // MARK: - 單例
    static let shared = FeedingRepository()
    
    private init() {}
    
    // MARK: - 實現方法
    
    func getFeedingRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[FeedingRecord], Error> {
        // 在實際應用中，這裡會從CoreData或其他數據源獲取數據
        // 這裡提供一個模擬實現
        return .success([])
    }
    
    func saveFeedingRecord(_ record: FeedingRecord) async -> Result<Void, Error> {
        // 在實際應用中，這裡會保存到CoreData或其他數據源
        // 這裡提供一個模擬實現
        return .success(())
    }
    
    func deleteFeedingRecord(id: String) async -> Result<Void, Error> {
        // 在實際應用中，這裡會從CoreData或其他數據源刪除
        // 這裡提供一個模擬實現
        return .success(())
    }
}
```

## 4. 依賴注入容器

```swift
// DependencyContainer.swift

import Foundation

/// 依賴注入容器
class DependencyContainer {
    // MARK: - 單例
    static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - 倉庫
    
    lazy var sleepRecordRepository: SleepRecordRepositoryProtocol = SleepRecordRepository.shared
    lazy var activityRepository: ActivityRepositoryProtocol = ActivityRepository.shared
    lazy var feedingRepository: FeedingRepositoryProtocol = FeedingRepository.shared
    
    // MARK: - 分析服務
    
    lazy var sleepPatternAnalyzer: SleepPatternAnalyzer = {
        return SleepPatternAnalyzer(sleepRepository: sleepRecordRepository)
    }()
    
    lazy var routineAnalyzer: RoutineAnalyzer = {
        return RoutineAnalyzer(
            activityRepository: activityRepository,
            sleepRepository: sleepRecordRepository,
            feedingRepository: feedingRepository
        )
    }()
    
    lazy var predictionEngine: PredictionEngine = {
        return PredictionEngine(
            sleepRepository: sleepRecordRepository,
            feedingRepository: feedingRepository,
            activityRepository: activityRepository,
            sleepPatternAnalyzer: sleepPatternAnalyzer,
            routineAnalyzer: routineAnalyzer
        )
    }()
    
    // MARK: - 網絡與設置
    
    lazy var networkMonitor: NetworkMonitor = NetworkMonitor.shared
    lazy var userSettings: UserSettings = UserSettings.shared
    
    // MARK: - API與安全
    
    lazy var apiKeyManager: APIKeyManager = APIKeyManager.shared
    lazy var dataAnonymizer: DataAnonymizer = DataAnonymizer.shared
    lazy var deepseekAPIClient: DeepseekAPIClient = DeepseekAPIClient.shared
    
    // MARK: - 雲端服務
    
    lazy var cloudAIService: CloudAIService = CloudAIService.shared
    
    // MARK: - AI引擎
    
    lazy var aiEngine: AIEngine = AIEngine.shared
}
```

## 5. 修正的DeepseekAPIClient（使用APIKeyManager）

```swift
// DeepseekAPIClient.swift（修正版）

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
```

## 6. 修正的DataAnonymizer（添加UIKit導入）

```swift
// DataAnonymizer.swift（修正版，僅顯示開頭部分）

import Foundation
import CryptoKit
import UIKit  // 添加UIKit導入

/// 負責對發送到雲端的數據進行匿名化處理
class DataAnonymizer {
    // MARK: - 單例模式
    static let shared = DataAnonymizer()
    
    private init() {}
    
    // 其餘代碼保持不變...
}
```

## 7. 修正的API Key實現（添加UIKit導入）

```swift
// APIKeyManager.swift（修正版，僅顯示開頭部分）

import Foundation
import Security
import CommonCrypto
import UIKit  // 添加UIKit導入

/// API Key管理器，負責安全存儲和獲取API Key
class APIKeyManager {
    // 其餘代碼保持不變...
}
```
