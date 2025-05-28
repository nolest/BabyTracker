# 寶寶生活記錄專業版（Baby Tracker）- 單一API Key實施計劃

## 1. 概述

本文檔詳細描述了「寶寶生活記錄專業版」應用在純客戶端環境下，使用單一Deepseek API Key進行初步整合與測試的實施計劃。這是API Key管理策略的第一階段實施，旨在驗證基本功能，為後續完整的多Key輪換機制奠定基礎。

### 1.1 目標

- 實現單一API Key的安全存儲與保護
- 實現基本的客戶端限流機制
- 實現簡單的結果緩存策略
- 提供完整的測試框架，驗證與Deepseek API的整合

### 1.2 實施範圍

- API Key安全存儲
- 基本請求管理
- 簡單限流機制
- 基礎緩存策略
- 錯誤處理與恢復

## 2. API Key安全存儲

即使在單Key階段，也需要實施基本的安全存儲機制：

### 2.1 分段存儲

- 將API Key分割成3個部分
- 部分1：存儲在代碼常量中（經過基本混淆）
- 部分2：存儲在加密的資源文件中
- 部分3：存儲在安全存儲（如iOS的Keychain）中

### 2.2 代碼實現

```swift
// APIKeyManager.swift

class APIKeyManager {
    private static let keyPart1 = "sk_7a1b" // 混淆後的代碼常量
    
    private static func getKeyPart2() -> String {
        guard let path = Bundle.main.path(forResource: "api_config", ofType: "bin"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return ""
        }
        
        // 簡單解密（實際實現會更複雜）
        let decryptedData = decryptData(data)
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
    private static func getKeyPart3() -> String {
        // 從Keychain獲取
        return KeychainManager.shared.getValue(forKey: "deepseek_key_part3") ?? ""
    }
    
    static func getAPIKey() -> String {
        // 組合三部分
        return keyPart1 + getKeyPart2() + getKeyPart3()
    }
    
    // 首次啟動時初始化Keychain部分
    static func initializeKeychain(with keyPart: String) {
        if KeychainManager.shared.getValue(forKey: "deepseek_key_part3") == nil {
            KeychainManager.shared.setValue(keyPart, forKey: "deepseek_key_part3")
        }
    }
}
```

## 3. 基本請求管理

### 3.1 API客戶端

設計一個基本的API客戶端，負責處理與Deepseek API的通信：

```swift
// DeepseekClient.swift

class DeepseekClient {
    static let shared = DeepseekClient()
    private init() {}
    
    private let baseURL = "https://api.deepseek.com"
    
    // 睡眠模式分析
    func analyzeSleepPattern(data: SleepData, completion: @escaping (Result<SleepAnalysis, Error>) -> Void) {
        // 檢查是否允許請求
        guard UsageLimiter.shared.canMakeRequest() else {
            completion(.failure(APIError.usageLimitExceeded))
            return
        }
        
        // 檢查緩存
        if let cachedResult = CacheManager.shared.getCachedSleepAnalysis(for: data.id) {
            completion(.success(cachedResult))
            return
        }
        
        // 準備請求
        let endpoint = "/v1/analyze/sleep"
        let apiKey = APIKeyManager.getAPIKey()
        
        // 構建請求體
        let requestBody = prepareRequestBody(from: data)
        
        // 發送請求
        sendRequest(to: endpoint, with: requestBody, apiKey: apiKey) { result in
            switch result {
            case .success(let responseData):
                // 解析響應
                do {
                    let analysis = try self.parseResponse(responseData)
                    
                    // 緩存結果
                    CacheManager.shared.cacheSleepAnalysis(analysis, for: data.id)
                    
                    // 記錄使用
                    UsageLimiter.shared.recordUsage()
                    
                    completion(.success(analysis))
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                self.handleAPIError(error, completion: completion)
            }
        }
    }
    
    // 其他分析方法（作息分析、預測等）...
    
    // 輔助方法
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
        let deviceFingerprint = DeviceIdentifier.getFingerprint()
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
                
            default:
                completion(.failure(APIError.serverError(statusCode: httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
    
    private func handleAPIError(_ error: Error, completion: @escaping (Result<SleepAnalysis, Error>) -> Void) {
        if case APIError.rateLimited = error {
            // 記錄限流事件
            UsageLimiter.shared.recordRateLimiting()
        }
        
        completion(.failure(error))
    }
    
    // 其他輔助方法...
}

// API錯誤類型
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case rateLimited
    case usageLimitExceeded
    case serverError(statusCode: Int)
    case parsingError
}
```

## 4. 基本限流機制

實現簡單的客戶端限流機制，防止過度使用API：

```swift
// UsageLimiter.swift

class UsageLimiter {
    static let shared = UsageLimiter()
    private init() {
        loadUsageHistory()
    }
    
    // 使用記錄
    private var usageHistory: [Date] = []
    private let maxHourlyRequests = 10
    private let maxDailyRequests = 30
    
    // 檢查是否可以發送請求
    func canMakeRequest() -> Bool {
        cleanupOldRecords()
        
        let hourAgo = Date().addingTimeInterval(-3600)
        let dayAgo = Date().addingTimeInterval(-86400)
        
        let hourlyRequests = usageHistory.filter { $0 >= hourAgo }.count
        let dailyRequests = usageHistory.filter { $0 >= dayAgo }.count
        
        return hourlyRequests < maxHourlyRequests && dailyRequests < maxDailyRequests
    }
    
    // 記錄API使用
    func recordUsage() {
        usageHistory.append(Date())
        saveUsageHistory()
    }
    
    // 記錄API限流事件
    func recordRateLimiting() {
        // 實現指數退避策略
        // 暫時增加本地限制
    }
    
    // 清理舊記錄
    private func cleanupOldRecords() {
        let dayAgo = Date().addingTimeInterval(-86400)
        usageHistory = usageHistory.filter { $0 >= dayAgo }
    }
    
    // 持久化存儲
    private func saveUsageHistory() {
        let timestamps = usageHistory.map { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(timestamps, forKey: "deepseek_api_usage_history")
    }
    
    private func loadUsageHistory() {
        if let timestamps = UserDefaults.standard.array(forKey: "deepseek_api_usage_history") as? [Double] {
            usageHistory = timestamps.map { Date(timeIntervalSince1970: $0) }
            cleanupOldRecords()
        }
    }
    
    // 獲取使用統計
    func getUsageStatistics() -> (hourly: Int, daily: Int, hourlyRemaining: Int, dailyRemaining: Int) {
        cleanupOldRecords()
        
        let hourAgo = Date().addingTimeInterval(-3600)
        let dayAgo = Date().addingTimeInterval(-86400)
        
        let hourlyRequests = usageHistory.filter { $0 >= hourAgo }.count
        let dailyRequests = usageHistory.filter { $0 >= dayAgo }.count
        
        return (
            hourly: hourlyRequests,
            daily: dailyRequests,
            hourlyRemaining: maxHourlyRequests - hourlyRequests,
            dailyRemaining: maxDailyRequests - dailyRequests
        )
    }
}
```

## 5. 基礎緩存策略

實現簡單的結果緩存，減少重複請求：

```swift
// CacheManager.swift

class CacheManager {
    static let shared = CacheManager()
    private init() {}
    
    // 緩存存儲
    private var sleepAnalysisCache: [String: (analysis: SleepAnalysis, timestamp: Date)] = [:]
    private var routineAnalysisCache: [String: (analysis: RoutineAnalysis, timestamp: Date)] = [:]
    private var predictionCache: [String: (prediction: Prediction, timestamp: Date)] = [:]
    
    // 緩存有效期（秒）
    private let sleepAnalysisCacheDuration: TimeInterval = 24 * 3600 // 24小時
    private let routineAnalysisCacheDuration: TimeInterval = 12 * 3600 // 12小時
    private let predictionCacheDuration: TimeInterval = 6 * 3600 // 6小時
    
    // 睡眠分析緩存
    func cacheSleepAnalysis(_ analysis: SleepAnalysis, for id: String) {
        sleepAnalysisCache[id] = (analysis, Date())
    }
    
    func getCachedSleepAnalysis(for id: String) -> SleepAnalysis? {
        guard let cached = sleepAnalysisCache[id],
              Date().timeIntervalSince(cached.timestamp) < sleepAnalysisCacheDuration else {
            return nil
        }
        
        return cached.analysis
    }
    
    // 作息分析緩存
    func cacheRoutineAnalysis(_ analysis: RoutineAnalysis, for id: String) {
        routineAnalysisCache[id] = (analysis, Date())
    }
    
    func getCachedRoutineAnalysis(for id: String) -> RoutineAnalysis? {
        guard let cached = routineAnalysisCache[id],
              Date().timeIntervalSince(cached.timestamp) < routineAnalysisCacheDuration else {
            return nil
        }
        
        return cached.analysis
    }
    
    // 預測緩存
    func cachePrediction(_ prediction: Prediction, for id: String) {
        predictionCache[id] = (prediction, Date())
    }
    
    func getCachedPrediction(for id: String) -> Prediction? {
        guard let cached = predictionCache[id],
              Date().timeIntervalSince(cached.timestamp) < predictionCacheDuration else {
            return nil
        }
        
        return cached.prediction
    }
    
    // 清理過期緩存
    func cleanupExpiredCache() {
        let now = Date()
        
        // 清理睡眠分析緩存
        sleepAnalysisCache = sleepAnalysisCache.filter {
            now.timeIntervalSince($0.value.timestamp) < sleepAnalysisCacheDuration
        }
        
        // 清理作息分析緩存
        routineAnalysisCache = routineAnalysisCache.filter {
            now.timeIntervalSince($0.value.timestamp) < routineAnalysisCacheDuration
        }
        
        // 清理預測緩存
        predictionCache = predictionCache.filter {
            now.timeIntervalSince($0.value.timestamp) < predictionCacheDuration
        }
    }
}
```

## 6. 設備標識與請求簽名

實現基本的設備標識和請求簽名機制：

```swift
// DeviceIdentifier.swift

class DeviceIdentifier {
    // 獲取設備指紋
    static func getFingerprint() -> String {
        // 組合多個設備特徵
        let deviceName = UIDevice.current.name
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        // 創建唯一指紋
        let fingerprintString = "\(deviceName)|\(deviceModel)|\(systemVersion)|\(identifierForVendor)"
        return fingerprintString.sha256()
    }
    
    // 獲取安裝ID
    static func getInstallationID() -> String {
        let key = "installation_id"
        
        // 檢查是否已存在
        if let existingID = UserDefaults.standard.string(forKey: key) {
            return existingID
        }
        
        // 創建新ID
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }
}

// 請求簽名生成
func generateRequestSignature(timestamp: String, deviceFingerprint: String) -> String {
    let installationID = DeviceIdentifier.getInstallationID()
    let signatureBase = "\(timestamp)|\(deviceFingerprint)|\(installationID)"
    return signatureBase.sha256()
}

// SHA-256 擴展
extension String {
    func sha256() -> String {
        if let stringData = self.data(using: .utf8) {
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            stringData.withUnsafeBytes {
                _ = CC_SHA256($0.baseAddress, CC_LONG(stringData.count), &digest)
            }
            return digest.map { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
}
```

## 7. 用戶界面整合

### 7.1 API使用狀態顯示

在設置頁面添加API使用狀態顯示：

```swift
// APIUsageView.swift

struct APIUsageView: View {
    @State private var usageStats: (hourly: Int, daily: Int, hourlyRemaining: Int, dailyRemaining: Int) = (0, 0, 0, 0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI分析使用情況")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("今日已使用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(usageStats.daily)/\(usageStats.daily + usageStats.dailyRemaining)")
                        .font(.title2)
                }
                Spacer()
                CircularProgressView(
                    progress: Double(usageStats.daily) / Double(usageStats.daily + usageStats.dailyRemaining),
                    color: usageStats.dailyRemaining > 5 ? .green : .orange
                )
                .frame(width: 44, height: 44)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("本小時已使用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(usageStats.hourly)/\(usageStats.hourly + usageStats.hourlyRemaining)")
                        .font(.title2)
                }
                Spacer()
                CircularProgressView(
                    progress: Double(usageStats.hourly) / Double(usageStats.hourly + usageStats.hourlyRemaining),
                    color: usageStats.hourlyRemaining > 2 ? .green : .orange
                )
                .frame(width: 44, height: 44)
            }
            
            if usageStats.hourlyRemaining == 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("已達到本小時分析限制，請稍後再試")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            updateUsageStats()
        }
    }
    
    private func updateUsageStats() {
        usageStats = UsageLimiter.shared.getUsageStatistics()
    }
}
```

### 7.2 分析結果來源標識

在分析結果中添加來源標識，區分本地分析和雲端分析：

```swift
struct AnalysisResultView: View {
    let analysis: SleepAnalysis
    let isFromCache: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分析結果內容...
            
            HStack {
                Image(systemName: isFromCache ? "clock.arrow.circlepath" : "cloud")
                    .foregroundColor(.secondary)
                Text(isFromCache ? "緩存結果" : "雲端分析")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(analysis.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
```

## 8. 測試計劃

### 8.1 單元測試

為關鍵組件編寫單元測試：

```swift
// APIKeyManagerTests.swift

class APIKeyManagerTests: XCTestCase {
    func testAPIKeyAssembly() {
        // 設置測試環境
        let testKeyPart3 = "test_key_part3"
        APIKeyManager.initializeKeychain(with: testKeyPart3)
        
        // 獲取API Key
        let apiKey = APIKeyManager.getAPIKey()
        
        // 驗證
        XCTAssertFalse(apiKey.isEmpty)
        XCTAssertTrue(apiKey.contains("sk_"))
    }
}

// UsageLimiterTests.swift

class UsageLimiterTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // 清除之前的使用記錄
        UserDefaults.standard.removeObject(forKey: "deepseek_api_usage_history")
    }
    
    func testUsageLimiting() {
        let limiter = UsageLimiter.shared
        
        // 初始狀態應允許請求
        XCTAssertTrue(limiter.canMakeRequest())
        
        // 模擬達到小時限制
        for _ in 0..<10 {
            limiter.recordUsage()
        }
        
        // 應該拒絕請求
        XCTAssertFalse(limiter.canMakeRequest())
        
        // 驗證統計
        let stats = limiter.getUsageStatistics()
        XCTAssertEqual(stats.hourly, 10)
        XCTAssertEqual(stats.hourlyRemaining, 0)
    }
}

// CacheManagerTests.swift

class CacheManagerTests: XCTestCase {
    func testSleepAnalysisCache() {
        let manager = CacheManager.shared
        let testId = "test_sleep_1"
        let testAnalysis = SleepAnalysis(id: testId, quality: 0.8, duration: 480, cycles: 4, timestamp: Date())
        
        // 緩存分析結果
        manager.cacheSleepAnalysis(testAnalysis, for: testId)
        
        // 獲取緩存
        let cached = manager.getCachedSleepAnalysis(for: testId)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.id, testId)
        
        // 測試過期緩存
        // 這需要模擬時間流逝或修改緩存時間戳
    }
}
```

### 8.2 整合測試

測試與Deepseek API的整合：

```swift
// DeepseekClientIntegrationTests.swift

class DeepseekClientIntegrationTests: XCTestCase {
    func testSleepAnalysis() {
        let expectation = self.expectation(description: "Sleep analysis completed")
        
        // 創建測試數據
        let sleepData = SleepData(
            id: "test_\(Date().timeIntervalSince1970)",
            startTime: Date().addingTimeInterval(-8 * 3600),
            endTime: Date(),
            interruptions: [],
            environmentFactors: EnvironmentFactors(light: 0.2, noise: 0.3, temperature: 22)
        )
        
        // 發送分析請求
        DeepseekClient.shared.analyzeSleepPattern(data: sleepData) { result in
            switch result {
            case .success(let analysis):
                // 驗證分析結果
                XCTAssertEqual(analysis.id, sleepData.id)
                XCTAssertGreaterThan(analysis.quality, 0)
                XCTAssertLessThanOrEqual(analysis.quality, 1)
                expectation.fulfill()
                
            case .failure(let error):
                XCTFail("Analysis failed with error: \(error)")
            }
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
}
```

### 8.3 UI測試

測試API使用狀態顯示：

```swift
// APIUsageUITests.swift

class APIUsageUITests: XCTestUITestCase {
    func testAPIUsageDisplay() {
        let app = XCUIApplication()
        app.launch()
        
        // 導航到設置頁面
        app.tabBars.buttons["設置"].tap()
        
        // 檢查API使用狀態顯示
        XCTAssertTrue(app.staticTexts["AI分析使用情況"].exists)
        
        // 驗證使用統計顯示
        XCTAssertTrue(app.staticTexts["今日已使用"].exists)
        XCTAssertTrue(app.staticTexts["本小時已使用"].exists)
    }
}
```

## 9. 實施計劃

單一API Key整合將分為以下階段實施：

### 9.1 準備階段

- 設置測試環境
- 實現基本的API Key管理器
- 實現設備標識與請求簽名

### 9.2 核心功能實施

- 實現DeepseekClient
- 實現UsageLimiter
- 實現CacheManager

### 9.3 UI整合

- 實現API使用狀態顯示
- 添加分析結果來源標識
- 優化用戶體驗

### 9.4 測試與驗證

- 執行單元測試
- 執行整合測試
- 執行UI測試
- 進行手動測試與驗證

## 10. 後續步驟

成功實施單一API Key整合後，將進行以下工作：

1. 收集測試結果與使用數據
2. 根據測試結果優化實現
3. 擴展到完整的多Key輪換機制
4. 實施更高級的安全保護措施

## 11. 結論

本文檔詳細描述了「寶寶生活記錄專業版」應用在純客戶端環境下，使用單一Deepseek API Key進行初步整合與測試的實施計劃。通過這一階段的實施，我們將驗證基本功能，為後續完整的多Key輪換機制奠定基礎。
