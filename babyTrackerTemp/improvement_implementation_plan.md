# 寶寶生活記錄專業版（Baby Tracker）- 整合改進實施方案

## 方案概述

本文檔詳細說明「寶寶生活記錄專業版（Baby Tracker）」iOS應用中第三階段與前兩階段整合的具體改進實施方案，包括高優先級和中優先級改進項目的詳細實施步驟、驗證標準和時間規劃。

## 改進項目總覽

### 高優先級改進項目

1. **依賴方向衝突修復**
   - AIEngine重構，確保通過UseCase層訪問數據
   - 明確DeepseekClient與AIEngine之間的依賴關係
   - 更新依賴注入配置

2. **異步處理模式統一**
   - 統一使用Combine框架
   - 為回調接口添加Combine適配器
   - 統一錯誤類型

3. **完善錯誤處理**
   - 統一使用Result類型
   - 完善錯誤傳播機制
   - 添加用戶友好的錯誤展示

4. **添加離線模式提示**
   - 優化網絡狀態監控
   - 添加離線模式UI提示
   - 實現功能可用性動態調整

### 中優先級改進項目

5. **統一數據轉換方式**
   - 創建統一的映射協議
   - 為所有模型實現映射協議
   - 在視圖模型中統一使用映射函數

6. **優化可視化整合**
   - 重構可視化組件，提高復用性
   - 創建統一的可視化組件
   - 在分析結果頁面使用統一的可視化組件

7. **添加分析設置界面**
   - 設計分析設置模型
   - 實現設置存儲服務
   - 創建分析設置界面
   - 在主界面添加設置入口

8. **改進分析過程透明度**
   - 設計分析進度模型
   - 在AIEngine中添加進度報告
   - 創建進度展示UI組件
   - 在分析頁面集成進度展示

## 詳細實施方案

### 1. 依賴方向衝突修復

#### 1.1 AIEngine重構

**目標**：確保AIEngine通過UseCase層訪問數據，而不是直接訪問Repository層。

**實施步驟**：

1. 識別AIEngine中直接訪問Repository的所有實例
   ```swift
   // 修改前
   class AIEngine {
       private let sleepRepository: SleepRepository
       // ...
   }
   ```

2. 創建或使用現有的UseCase接口
   ```swift
   protocol SleepUseCase {
       func getSleepRecords(for babyId: UUID) -> AnyPublisher<[SleepRecord], Error>
       // 其他方法...
   }
   ```

3. 修改AIEngine，使用UseCase而不是Repository
   ```swift
   // 修改後
   class AIEngine {
       private let sleepUseCase: SleepUseCase
       // ...
   }
   ```

4. 更新AIEngine中的所有數據訪問代碼，使用UseCase方法
   ```swift
   // 修改前
   let sleepRecords = sleepRepository.getSleepRecords(for: babyId)
   
   // 修改後
   let sleepRecords = sleepUseCase.getSleepRecords(for: babyId)
   ```

5. 更新單元測試，使用模擬的UseCase而不是Repository

**驗證標準**：
- AIEngine不再直接引用任何Repository
- 所有數據訪問都通過UseCase層
- 單元測試通過
- 功能測試確認數據流正常

#### 1.2 明確依賴關係

**目標**：解決DeepseekClient與AIEngine之間的循環依賴，建立清晰的單向依賴關係。

**實施步驟**：

1. 分析當前依賴關係
   ```swift
   // 當前可能存在的循環依賴
   class DeepseekClient {
       var aiEngine: AIEngine?
       // ...
   }
   
   class AIEngine {
       var deepseekClient: DeepseekClient?
       // ...
   }
   ```

2. 決定依賴方向（建議AIEngine依賴DeepseekClient）
   ```swift
   // 修改後
   class DeepseekClient {
       // 不再持有AIEngine引用
       // ...
   }
   
   class AIEngine {
       private let deepseekClient: DeepseekClient
       
       init(deepseekClient: DeepseekClient) {
           self.deepseekClient = deepseekClient
       }
       // ...
   }
   ```

3. 如果DeepseekClient需要回調AIEngine，使用回調函數或代理模式
   ```swift
   protocol AnalysisResultHandler {
       func handleAnalysisResult(_ result: AnalysisResult)
       func handleAnalysisError(_ error: Error)
   }
   
   class AIEngine: AnalysisResultHandler {
       // 實現處理方法...
   }
   
   class DeepseekClient {
       weak var resultHandler: AnalysisResultHandler?
       
       func performAnalysis() {
           // 分析完成後
           resultHandler?.handleAnalysisResult(result)
       }
   }
   ```

4. 更新所有相關代碼，確保遵循新的依賴關係

**驗證標準**：
- 不存在循環依賴
- 依賴關係清晰可見
- 所有功能正常工作
- 代碼更容易理解和維護

#### 1.3 更新依賴注入配置

**目標**：確保依賴注入配置反映新的依賴關係。

**實施步驟**：

1. 更新依賴注入容器配置
   ```swift
   // 修改前
   container.register(AIEngine.self) { r in
       let engine = AIEngine(sleepRepository: r.resolve(SleepRepository.self)!)
       engine.deepseekClient = r.resolve(DeepseekClient.self)
       return engine
   }
   
   // 修改後
   container.register(AIEngine.self) { r in
       AIEngine(
           sleepUseCase: r.resolve(SleepUseCase.self)!,
           deepseekClient: r.resolve(DeepseekClient.self)!
       )
   }
   ```

2. 確保所有依賴都正確註冊
   ```swift
   container.register(SleepRepository.self) { _ in SleepRepositoryImpl() }
   container.register(SleepUseCase.self) { r in
       SleepUseCaseImpl(repository: r.resolve(SleepRepository.self)!)
   }
   container.register(DeepseekClient.self) { _ in DeepseekClientImpl() }
   ```

3. 更新所有使用這些組件的地方，確保使用正確的依賴

**驗證標準**：
- 依賴注入配置正確反映新的依賴關係
- 所有組件都能正確解析其依賴
- 應用啟動和運行正常

### 2. 異步處理模式統一

#### 2.1 統一使用Combine

**目標**：將所有異步操作統一使用Combine框架。

**實施步驟**：

1. 識別所有使用回調的異步接口
   ```swift
   // 使用回調的接口
   func getSleepRecords(for babyId: UUID, completion: @escaping ([SleepRecord]) -> Void)
   func analyzeSleepPattern(for babyId: UUID, completion: @escaping (Result<SleepPatternAnalysisResult, Error>) -> Void)
   ```

2. 為這些接口添加Combine版本
   ```swift
   // 添加Combine版本
   func getSleepRecordsPublisher(for babyId: UUID) -> AnyPublisher<[SleepRecord], Error>
   func analyzeSleepPatternPublisher(for babyId: UUID) -> AnyPublisher<SleepPatternAnalysisResult, Error>
   ```

3. 在實現中，可以讓Combine版本調用回調版本，或反之
   ```swift
   // Combine版本調用回調版本
   func getSleepRecordsPublisher(for babyId: UUID) -> AnyPublisher<[SleepRecord], Error> {
       return Future<[SleepRecord], Error> { promise in
           self.getSleepRecords(for: babyId) { records in
               promise(.success(records))
           }
       }.eraseToAnyPublisher()
   }
   
   // 回調版本調用Combine版本
   func getSleepRecords(for babyId: UUID, completion: @escaping ([SleepRecord]) -> Void) {
       getSleepRecordsPublisher(for: babyId)
           .sink(
               receiveCompletion: { _ in },
               receiveValue: { records in
                   completion(records)
               }
           )
           .store(in: &cancellables)
   }
   ```

4. 逐步更新所有使用這些接口的代碼，優先使用Combine版本

**驗證標準**：
- 所有異步接口都提供Combine版本
- 新代碼統一使用Combine版本
- 功能測試確認所有異步操作正常工作

#### 2.2 為回調接口添加Combine適配器

**目標**：為現有的回調接口添加Combine適配器，避免大規模重寫。

**實施步驟**：

1. 創建通用的Combine適配器擴展
   ```swift
   extension SleepRepository {
       // 為回調接口添加Combine包裝
       func getSleepRecordsPublisher(for babyId: UUID) -> AnyPublisher<[SleepRecord], Error> {
           return Future<[SleepRecord], Error> { promise in
               self.getSleepRecords(for: babyId) { records in
                   promise(.success(records))
               }
           }.eraseToAnyPublisher()
       }
   }
   ```

2. 為帶有錯誤回調的接口添加適配器
   ```swift
   extension AIEngine {
       // 為帶有錯誤回調的接口添加Combine包裝
       func analyzeSleepPatternPublisher(for babyId: UUID) -> AnyPublisher<SleepPatternAnalysisResult, Error> {
           return Future<SleepPatternAnalysisResult, Error> { promise in
               self.analyzeSleepPattern(for: babyId) { result in
                   switch result {
                   case .success(let analysisResult):
                       promise(.success(analysisResult))
                   case .failure(let error):
                       promise(.failure(error))
                   }
               }
           }.eraseToAnyPublisher()
       }
   }
   ```

3. 在視圖模型中使用這些適配器
   ```swift
   class SleepAnalysisViewModel: ObservableObject {
       // 使用Combine適配器
       func analyzeSleepPattern() {
           aiEngine.analyzeSleepPatternPublisher(for: selectedBabyId)
               .receive(on: DispatchQueue.main)
               .sink(
                   receiveCompletion: { [weak self] completion in
                       // 處理完成...
                   },
                   receiveValue: { [weak self] result in
                       // 處理結果...
                   }
               )
               .store(in: &cancellables)
       }
   }
   ```

**驗證標準**：
- 所有回調接口都有對應的Combine適配器
- 視圖模型中統一使用Combine
- 功能測試確認適配器正常工作

#### 2.3 統一錯誤類型

**目標**：定義並使用統一的錯誤類型，確保錯誤處理一致性。

**實施步驟**：

1. 定義統一的錯誤類型
   ```swift
   enum AppError: Error {
       case network(NetworkError)
       case database(DatabaseError)
       case analysis(AnalysisError)
       case unknown(Error)
       
       var localizedDescription: String {
           switch self {
           case .network(let error):
               return "網絡錯誤: \(error.localizedDescription)"
           case .database(let error):
               return "數據庫錯誤: \(error.localizedDescription)"
           case .analysis(let error):
               return "分析錯誤: \(error.localizedDescription)"
           case .unknown(let error):
               return "未知錯誤: \(error.localizedDescription)"
           }
       }
   }
   ```

2. 定義各子系統的錯誤類型
   ```swift
   enum NetworkError: Error {
       case connectionFailed
       case timeout
       case serverError(Int)
       case invalidResponse
       // 其他網絡錯誤...
   }
   
   enum DatabaseError: Error {
       case readFailed
       case writeFailed
       case entityNotFound
       case invalidData
       // 其他數據庫錯誤...
   }
   
   enum AnalysisError: Error {
       case insufficientData
       case invalidPattern
       case processingFailed
       // 其他分析錯誤...
   }
   ```

3. 在所有Publisher中使用統一的錯誤類型
   ```swift
   func getSleepRecordsPublisher(for babyId: UUID) -> AnyPublisher<[SleepRecord], AppError> {
       return originalPublisher
           .mapError { error in
               if let networkError = error as? NetworkError {
                   return .network(networkError)
               } else if let dbError = error as? DatabaseError {
                   return .database(dbError)
               } else if let analysisError = error as? AnalysisError {
                   return .analysis(analysisError)
               } else {
                   return .unknown(error)
               }
           }
           .eraseToAnyPublisher()
   }
   ```

4. 更新所有錯誤處理代碼，使用新的錯誤類型

**驗證標準**：
- 所有Publisher使用統一的AppError類型
- 錯誤處理代碼能正確識別和處理不同類型的錯誤
- 用戶界面顯示友好的錯誤信息

### 3. 完善錯誤處理

#### 3.1 統一使用Result類型

**目標**：在非Combine接口中統一使用Result類型處理錯誤。

**實施步驟**：

1. 識別所有不使用Result類型的錯誤處理接口
   ```swift
   // 修改前：直接拋出錯誤
   func analyzeSleepPattern(for babyId: UUID) throws -> SleepPatternAnalysisResult
   ```

2. 修改這些接口，使用Result類型
   ```swift
   // 修改後：使用Result類型
   func analyzeSleepPattern(for babyId: UUID) -> Result<SleepPatternAnalysisResult, AppError>
   ```

3. 更新實現，使用Result.success和Result.failure
   ```swift
   func analyzeSleepPattern(for babyId: UUID) -> Result<SleepPatternAnalysisResult, AppError> {
       do {
           // 分析邏輯...
           return .success(result)
       } catch let error as NetworkError {
           return .failure(.network(error))
       } catch let error as DatabaseError {
           return .failure(.database(error))
       } catch let error as AnalysisError {
           return .failure(.analysis(error))
       } catch {
           return .failure(.unknown(error))
       }
   }
   ```

4. 更新調用代碼，處理Result
   ```swift
   let result = aiEngine.analyzeSleepPattern(for: babyId)
   switch result {
   case .success(let analysisResult):
       // 處理成功結果
   case .failure(let error):
       // 處理錯誤
   }
   ```

**驗證標準**：
- 所有非Combine接口都使用Result類型
- 錯誤處理代碼統一且易於理解
- 功能測試確認錯誤處理正常工作

#### 3.2 完善錯誤傳播機制

**目標**：確保所有錯誤都能正確傳播到UI層，並提供足夠的上下文信息。

**實施步驟**：

1. 在視圖模型中添加錯誤狀態
   ```swift
   class SleepAnalysisViewModel: ObservableObject {
       @Published var analysisResult: SleepPatternAnalysisResult?
       @Published var isLoading = false
       @Published var error: AppError?
       
       // 其他屬性和方法...
   }
   ```

2. 在視圖模型中處理和傳播錯誤
   ```swift
   func analyzeSleepPattern(for babyId: UUID) {
       isLoading = true
       error = nil
       
       aiEngine.analyzeSleepPatternPublisher(for: babyId)
           .receive(on: DispatchQueue.main)
           .sink(
               receiveCompletion: { [weak self] completion in
                   self?.isLoading = false
                   if case .failure(let error) = completion {
                       self?.error = error
                   }
               },
               receiveValue: { [weak self] result in
                   self?.analysisResult = result
               }
           )
           .store(in: &cancellables)
   }
   ```

3. 添加錯誤恢復機制
   ```swift
   func retry() {
       guard let babyId = selectedBabyId else { return }
       analyzeSleepPattern(for: babyId)
   }
   
   func clearError() {
       error = nil
   }
   ```

**驗證標準**：
- 所有錯誤都能正確傳播到視圖模型
- 視圖模型提供錯誤狀態和恢復機制
- 用戶界面能夠顯示錯誤並提供重試選項

#### 3.3 添加用戶友好的錯誤展示

**目標**：創建統一的錯誤展示組件，以用戶友好的方式顯示錯誤信息。

**實施步驟**：

1. 創建錯誤展示組件
   ```swift
   struct ErrorView: View {
       let error: AppError
       let retryAction: () -> Void
       
       var body: some View {
           VStack(spacing: 16) {
               Image(systemName: "exclamationmark.triangle")
                   .font(.system(size: 50))
                   .foregroundColor(.orange)
               
               Text(errorTitle)
                   .font(.headline)
               
               Text(errorMessage)
                   .font(.subheadline)
                   .multilineTextAlignment(.center)
                   .padding(.horizontal)
               
               Button("重試") {
                   retryAction()
               }
               .buttonStyle(.borderedProminent)
           }
           .padding()
           .background(
               RoundedRectangle(cornerRadius: 12)
                   .fill(Color(.systemBackground))
                   .shadow(radius: 4)
           )
           .padding()
       }
       
       private var errorTitle: String {
           switch error {
           case .network:
               return "網絡連接問題"
           case .database:
               return "數據存取問題"
           case .analysis:
               return "分析處理問題"
           case .unknown:
               return "未知問題"
           }
       }
       
       private var errorMessage: String {
           switch error {
           case .network(let networkError):
               return "無法連接到雲端分析服務：\(networkError.localizedDescription)。請檢查您的網絡連接並重試。"
           case .database(let dbError):
               return "無法讀取寶寶數據：\(dbError.localizedDescription)。請重新啟動應用並重試。"
           case .analysis(let analysisError):
               return "分析過程中出現問題：\(analysisError.localizedDescription)。請確保有足夠的數據進行分析。"
           case .unknown(let error):
               return "發生未知錯誤：\(error.localizedDescription)。請重試或聯繫客服支持。"
           }
       }
   }
   ```

2. 在視圖中使用錯誤展示組件
   ```swift
   struct SleepAnalysisView: View {
       @ObservedObject var viewModel: SleepAnalysisViewModel
       
       var body: some View {
           VStack {
               if viewModel.isLoading {
                   ProgressView("分析中...")
               } else if let error = viewModel.error {
                   ErrorView(error: error, retryAction: {
                       viewModel.retry()
                   })
               } else if let result = viewModel.analysisResult {
                   SleepAnalysisResultView(result: result)
               } else {
                   Text("請選擇寶寶並開始分析")
               }
           }
       }
   }
   ```

3. 確保所有錯誤展示使用統一的組件

**驗證標準**：
- 所有錯誤都使用統一的錯誤展示組件
- 錯誤信息清晰、友好且提供解決建議
- 用戶可以輕鬆理解錯誤並採取適當的行動

### 4. 添加離線模式提示

#### 4.1 優化網絡狀態監控

**目標**：改進網絡狀態監控，提供更詳細的連接信息。

**實施步驟**：

1. 擴展NetworkMonitor類
   ```swift
   class NetworkMonitor: ObservableObject {
       enum ConnectionType {
           case wifi
           case cellular
           case ethernet
           case unknown
       }
       
       enum ConnectionQuality {
           case excellent
           case good
           case fair
           case poor
           case unknown
       }
       
       @Published var isConnected = false
       @Published var connectionType: ConnectionType = .unknown
       @Published var connectionQuality: ConnectionQuality = .unknown
       
       private let monitor = NWPathMonitor()
       private let queue = DispatchQueue(label: "NetworkMonitor")
       
       init() {
           monitor.pathUpdateHandler = { [weak self] path in
               DispatchQueue.main.async {
                   self?.isConnected = path.status == .satisfied
                   self?.updateConnectionType(path)
                   self?.updateConnectionQuality(path)
               }
           }
           monitor.start(queue: queue)
       }
       
       private func updateConnectionType(_ path: NWPath) {
           if path.usesInterfaceType(.wifi) {
               connectionType = .wifi
           } else if path.usesInterfaceType(.cellular) {
               connectionType = .cellular
           } else if path.usesInterfaceType(.wiredEthernet) {
               connectionType = .ethernet
           } else {
               connectionType = .unknown
           }
       }
       
       private func updateConnectionQuality(_ path: NWPath) {
           // 根據路徑屬性評估連接質量
           // 這是一個簡化的實現，實際應用中可能需要更複雜的邏輯
           switch path.status {
           case .satisfied:
               if path.isExpensive {
                   connectionQuality = .fair
               } else {
                   connectionQuality = .good
               }
           case .unsatisfied:
               connectionQuality = .poor
           case .requiresConnection:
               connectionQuality = .unknown
           @unknown default:
               connectionQuality = .unknown
           }
       }
   }
   ```

2. 在應用中註冊NetworkMonitor
   ```swift
   @main
   struct BabyTrackerApp: App {
       @StateObject private var networkMonitor = NetworkMonitor()
       
       var body: some Scene {
           WindowGroup {
               ContentView()
                   .environmentObject(networkMonitor)
           }
       }
   }
   ```

**驗證標準**：
- NetworkMonitor能夠正確檢測網絡狀態變化
- 連接類型和質量信息準確
- 網絡狀態變化能夠及時反映在UI上

#### 4.2 添加離線模式UI提示

**目標**：在離線模式下提供明確的UI提示，說明功能限制。

**實施步驟**：

1. 創建離線模式提示橫幅
   ```swift
   struct OfflineBanner: View {
       enum AnalysisType {
           case sleep
           case routine
           case prediction
       }
       
       let analysisType: AnalysisType
       
       var body: some View {
           HStack {
               Image(systemName: "wifi.slash")
                   .foregroundColor(.white)
               
               Text(message)
                   .font(.subheadline)
                   .foregroundColor(.white)
               
               Spacer()
           }
           .padding(.vertical, 8)
           .padding(.horizontal, 12)
           .background(Color.orange)
           .cornerRadius(8)
           .padding(.horizontal)
       }
       
       private var message: String {
           switch analysisType {
           case .sleep:
               return "離線模式：僅提供基本睡眠分析，高級模式識別和環境影響分析不可用"
           case .routine:
               return "離線模式：僅提供基本作息分析，典型模式識別和規律性評分不可用"
           case .prediction:
               return "離線模式：僅提供基本預測，準確度有限"
           }
       }
   }
   ```

2. 在分析頁面添加離線模式提示
   ```swift
   struct SleepAnalysisView: View {
       @ObservedObject var viewModel: SleepAnalysisViewModel
       @EnvironmentObject var networkMonitor: NetworkMonitor
       
       var body: some View {
           VStack {
               if !networkMonitor.isConnected {
                   OfflineBanner(analysisType: .sleep)
               }
               
               // 其他UI...
           }
       }
   }
   ```

**驗證標準**：
- 離線模式下顯示明確的提示橫幅
- 提示信息清晰說明功能限制
- 用戶能夠理解離線模式的影響

#### 4.3 實現功能可用性動態調整

**目標**：根據網絡狀態動態調整功能可用性，確保用戶體驗流暢。

**實施步驟**：

1. 在視圖模型中添加功能可用性狀態
   ```swift
   class SleepAnalysisViewModel: ObservableObject {
       enum AnalysisType: String, CaseIterable, Identifiable {
           case basic = "basic"
           case advanced = "advanced"
           case environmental = "environmental"
           
           var id: String { rawValue }
           
           var displayName: String {
               switch self {
               case .basic: return "基本分析"
               case .advanced: return "高級分析"
               case .environmental: return "環境影響分析"
               }
           }
           
           var requiresNetwork: Bool {
               switch self {
               case .basic: return false
               case .advanced, .environmental: return true
               }
           }
       }
       
       @Published var availableAnalysisTypes: [AnalysisType] = []
       @Published var selectedAnalysisType: AnalysisType = .basic
       
       private let networkMonitor: NetworkMonitor
       private var cancellables = Set<AnyCancellable>()
       
       init(aiEngine: AIEngine, networkMonitor: NetworkMonitor) {
           self.aiEngine = aiEngine
           self.networkMonitor = networkMonitor
           
           // 監聽網絡狀態變化
           networkMonitor.$isConnected
               .receive(on: DispatchQueue.main)
               .sink { [weak self] isConnected in
                   self?.updateAvailableAnalysisTypes(isConnected: isConnected)
               }
               .store(in: &cancellables)
           
           // 初始化可用分析類型
           updateAvailableAnalysisTypes(isConnected: networkMonitor.isConnected)
       }
       
       private func updateAvailableAnalysisTypes(isConnected: Bool) {
           if isConnected {
               // 在線模式：所有分析類型可用
               availableAnalysisTypes = AnalysisType.allCases
           } else {
               // 離線模式：僅基本分析可用
               availableAnalysisTypes = AnalysisType.allCases.filter { !$0.requiresNetwork }
           }
           
           // 如果當前選擇的分析類型不可用，則切換到可用的類型
           if !availableAnalysisTypes.contains(selectedAnalysisType) {
               selectedAnalysisType = availableAnalysisTypes.first ?? .basic
           }
       }
   }
   ```

2. 在UI中反映功能可用性
   ```swift
   struct AnalysisTypeSelector: View {
       @ObservedObject var viewModel: SleepAnalysisViewModel
       
       var body: some View {
           Picker("分析類型", selection: $viewModel.selectedAnalysisType) {
               ForEach(viewModel.availableAnalysisTypes) { type in
                   Text(type.displayName).tag(type)
               }
           }
           .pickerStyle(.segmented)
       }
   }
   ```

3. 在分析頁面集成分析類型選擇器
   ```swift
   struct SleepAnalysisView: View {
       @ObservedObject var viewModel: SleepAnalysisViewModel
       @EnvironmentObject var networkMonitor: NetworkMonitor
       
       var body: some View {
           VStack {
               if !networkMonitor.isConnected {
                   OfflineBanner(analysisType: .sleep)
               }
               
               AnalysisTypeSelector(viewModel: viewModel)
                   .padding()
               
               // 其他UI...
           }
       }
   }
   ```

**驗證標準**：
- 離線模式下只顯示基本分析選項
- 在線模式下顯示所有分析選項
- 網絡狀態變化時，功能可用性自動調整
- 用戶選擇的分析類型在網絡狀態變化時能夠適當調整

### 5. 統一數據轉換方式

#### 5.1 創建統一的映射協議

**目標**：定義統一的映射協議，確保數據轉換的一致性。

**實施步驟**：

1. 定義領域模型到視圖模型的映射協議
   ```swift
   protocol ViewModelConvertible {
       associatedtype ViewModel
       
       func toViewModel() -> ViewModel
   }
   ```

2. 定義視圖模型到領域模型的映射協議
   ```swift
   protocol DomainModelConvertible {
       associatedtype DomainModel
       
       func toDomain() -> DomainModel
   }
   ```

3. 定義實體到領域模型的映射協議
   ```swift
   protocol EntityConvertible {
       associatedtype Entity
       
       func toEntity() -> Entity
   }
   ```

4. 定義領域模型到實體的映射協議
   ```swift
   protocol DomainEntityConvertible {
       associatedtype DomainEntity
       
       func toDomainEntity() -> DomainEntity
   }
   ```

**驗證標準**：
- 映射協議定義清晰且易於使用
- 協議能夠滿足所有數據轉換需求
- 協議設計符合Swift語言最佳實踐

#### 5.2 為所有模型實現映射協議

**目標**：為所有關鍵模型實現映射協議，確保數據轉換的一致性。

**實施步驟**：

1. 為領域模型實現ViewModelConvertible協議
   ```swift
   extension SleepPatternAnalysisResult: ViewModelConvertible {
       typealias ViewModel = SleepPatternAnalysisViewModel
       
       func toViewModel() -> SleepPatternAnalysisViewModel {
           return SleepPatternAnalysisViewModel(
               id: self.id,
               babyId: self.babyId,
               analysisDate: self.analysisDate,
               sleepEfficiency: self.sleepEfficiency,
               sleepQualityScore: self.sleepQualityScore,
               averageSleepDuration: self.averageSleepDuration,
               sleepCycleCount: self.sleepCycleCount,
               environmentalFactors: self.environmentalFactors.map { $0.toViewModel() },
               recommendations: self.recommendations.map { $0.toViewModel() },
               analysisSource: self.analysisSource.toViewModel()
           )
       }
   }
   ```

2. 為視圖模型實現DomainModelConvertible協議
   ```swift
   extension SleepPatternAnalysisViewModel: DomainModelConvertible {
       typealias DomainModel = SleepPatternAnalysisResult
       
       func toDomain() -> SleepPatternAnalysisResult {
           return SleepPatternAnalysisResult(
               id: self.id,
               babyId: self.babyId,
               analysisDate: self.analysisDate,
               sleepEfficiency: self.sleepEfficiency,
               sleepQualityScore: self.sleepQualityScore,
               averageSleepDuration: self.averageSleepDuration,
               sleepCycleCount: self.sleepCycleCount,
               environmentalFactors: self.environmentalFactors.map { $0.toDomain() },
               recommendations: self.recommendations.map { $0.toDomain() },
               analysisSource: self.analysisSource.toDomain()
           )
       }
   }
   ```

3. 為實體實現DomainEntityConvertible協議
   ```swift
   extension SleepRecordEntity: DomainEntityConvertible {
       typealias DomainEntity = SleepRecord
       
       func toDomainEntity() -> SleepRecord {
           return SleepRecord(
               id: self.id ?? UUID(),
               babyId: self.babyId ?? UUID(),
               startTime: self.startTime ?? Date(),
               endTime: self.endTime,
               duration: self.duration,
               quality: SleepQuality(rawValue: self.quality ?? "") ?? .unknown,
               notes: self.notes,
               environmentalFactors: self.environmentalFactors?.map { $0.toDomainEntity() } ?? []
           )
       }
   }
   ```

4. 為領域模型實現EntityConvertible協議
   ```swift
   extension SleepRecord: EntityConvertible {
       typealias Entity = SleepRecordEntity
       
       func toEntity() -> SleepRecordEntity {
           let entity = SleepRecordEntity()
           entity.id = self.id
           entity.babyId = self.babyId
           entity.startTime = self.startTime
           entity.endTime = self.endTime
           entity.duration = self.duration
           entity.quality = self.quality.rawValue
           entity.notes = self.notes
           entity.environmentalFactors = self.environmentalFactors.map { $0.toEntity() }
           return entity
       }
   }
   ```

**驗證標準**：
- 所有關鍵模型都實現了適當的映射協議
- 映射實現正確且完整
- 單元測試確認映射功能正常工作

#### 5.3 在視圖模型中統一使用映射函數

**目標**：確保所有視圖模型中的數據轉換都使用映射函數，而不是直接賦值。

**實施步驟**：

1. 識別所有使用直接賦值的地方
   ```swift
   // 修改前：直接賦值
   func updateWithAnalysisResult(_ result: SleepPatternAnalysisResult) {
       self.sleepEfficiency = result.sleepEfficiency
       self.sleepQualityScore = result.sleepQualityScore
       self.averageSleepDuration = result.averageSleepDuration
       // 更多賦值...
   }
   ```

2. 修改為使用映射函數
   ```swift
   // 修改後：使用映射函數
   func updateWithAnalysisResult(_ result: SleepPatternAnalysisResult) {
       let viewModel = result.toViewModel()
       self.update(from: viewModel)
   }
   
   func update(from viewModel: SleepPatternAnalysisViewModel) {
       self.sleepEfficiency = viewModel.sleepEfficiency
       self.sleepQualityScore = viewModel.sleepQualityScore
       self.averageSleepDuration = viewModel.averageSleepDuration
       // 更多賦值...
   }
   ```

3. 確保所有數據轉換都使用映射函數

**驗證標準**：
- 所有視圖模型中的數據轉換都使用映射函數
- 沒有直接賦值的情況
- 功能測試確認數據轉換正常工作

### 6. 優化可視化整合

#### 6.1 重構可視化組件，提高復用性

**目標**：重構可視化組件，使其更加通用和可復用。

**實施步驟**：

1. 定義通用的圖表數據協議
   ```swift
   protocol ChartDataConvertible {
       func toBarChartData() -> BarChartData
       func toLineChartData() -> LineChartData
       func toPieChartData() -> PieChartData
   }
   ```

2. 為分析結果實現圖表數據協議
   ```swift
   extension SleepPatternAnalysisResult: ChartDataConvertible {
       func toBarChartData() -> BarChartData {
           // 實現...
           return BarChartData(
               dataSets: [
                   BarChartDataSet(
                       entries: sleepDurations.enumerated().map { index, duration in
                           BarChartDataEntry(x: Double(index), y: duration)
                       },
                       label: "睡眠時長"
                   )
               ],
               labels: dates.map { dateFormatter.string(from: $0) }
           )
       }
       
       func toLineChartData() -> LineChartData {
           // 實現...
           return LineChartData(
               dataSets: [
                   LineChartDataSet(
                       entries: sleepQualityScores.enumerated().map { index, score in
                           ChartDataEntry(x: Double(index), y: score)
                       },
                       label: "睡眠質量"
                   )
               ],
               labels: dates.map { dateFormatter.string(from: $0) }
           )
       }
       
       func toPieChartData() -> PieChartData {
           // 實現...
           return PieChartData(
               dataSets: [
                   PieChartDataSet(
                       entries: sleepQualityDistribution.map { quality, percentage in
                           PieChartDataEntry(value: percentage, label: quality.displayName)
                       },
                       label: "睡眠質量分布"
                   )
               ]
           )
       }
   }
   ```

3. 為其他分析結果實現類似的協議

**驗證標準**：
- 圖表數據協議定義清晰且易於使用
- 分析結果能夠正確轉換為各種圖表數據
- 單元測試確認轉換功能正常工作

#### 6.2 創建統一的可視化組件

**目標**：創建統一的可視化組件，確保視覺風格一致。

**實施步驟**：

1. 創建通用的折線圖組件
   ```swift
   struct LineChartView: View {
       let data: LineChartData
       let title: String
       let subtitle: String?
       
       var body: some View {
           VStack(alignment: .leading) {
               Text(title)
                   .font(.headline)
               
               if let subtitle = subtitle {
                   Text(subtitle)
                       .font(.subheadline)
                       .foregroundColor(.secondary)
               }
               
               // 使用SwiftUI繪製折線圖
               // 或者使用第三方庫如SwiftUICharts
               // 這裡是一個簡化的實現
               GeometryReader { geometry in
                   Path { path in
                       let xScale = geometry.size.width / CGFloat(data.dataSets[0].entries.count - 1)
                       let yScale = geometry.size.height / 100
                       
                       let points = data.dataSets[0].entries.enumerated().map { index, entry in
                           CGPoint(
                               x: CGFloat(index) * xScale,
                               y: geometry.size.height - CGFloat(entry.y) * yScale
                           )
                       }
                       
                       path.move(to: points[0])
                       for point in points.dropFirst() {
                           path.addLine(to: point)
                       }
                   }
                   .stroke(Color.blue, lineWidth: 2)
               }
               .frame(height: 200)
               .padding(.vertical)
           }
           .padding()
           .background(
               RoundedRectangle(cornerRadius: 12)
                   .fill(Color(.systemBackground))
                   .shadow(radius: 2)
           )
       }
   }
   ```

2. 創建通用的柱狀圖組件
   ```swift
   struct BarChartView: View {
       let data: BarChartData
       let title: String
       let subtitle: String?
       
       var body: some View {
           VStack(alignment: .leading) {
               Text(title)
                   .font(.headline)
               
               if let subtitle = subtitle {
                   Text(subtitle)
                       .font(.subheadline)
                       .foregroundColor(.secondary)
               }
               
               // 使用SwiftUI繪製柱狀圖
               // 或者使用第三方庫如SwiftUICharts
               // 這裡是一個簡化的實現
               GeometryReader { geometry in
                   HStack(alignment: .bottom, spacing: 4) {
                       ForEach(0..<data.dataSets[0].entries.count, id: \.self) { index in
                           let entry = data.dataSets[0].entries[index]
                           let height = CGFloat(entry.y) / 100 * geometry.size.height
                           
                           VStack {
                               Rectangle()
                                   .fill(Color.blue)
                                   .frame(width: 20, height: height)
                               
                               Text(data.labels[index])
                                   .font(.caption)
                                   .rotationEffect(.degrees(-45))
                           }
                       }
                   }
                   .frame(height: 200)
               }
               .padding(.vertical)
           }
           .padding()
           .background(
               RoundedRectangle(cornerRadius: 12)
                   .fill(Color(.systemBackground))
                   .shadow(radius: 2)
           )
       }
   }
   ```

3. 創建通用的餅圖組件
   ```swift
   struct PieChartView: View {
       let data: PieChartData
       let title: String
       let subtitle: String?
       
       var body: some View {
           VStack(alignment: .leading) {
               Text(title)
                   .font(.headline)
               
               if let subtitle = subtitle {
                   Text(subtitle)
                       .font(.subheadline)
                       .foregroundColor(.secondary)
               }
               
               // 使用SwiftUI繪製餅圖
               // 或者使用第三方庫如SwiftUICharts
               // 這裡是一個簡化的實現
               GeometryReader { geometry in
                   ZStack {
                       ForEach(0..<data.dataSets[0].entries.count, id: \.self) { index in
                           let entry = data.dataSets[0].entries[index]
                           let startAngle = index == 0 ? 0 : data.dataSets[0].entries[0..<index].reduce(0) { $0 + $1.value } / data.dataSets[0].entries.reduce(0) { $0 + $1.value } * 360
                           let endAngle = (data.dataSets[0].entries[0...index].reduce(0) { $0 + $1.value } / data.dataSets[0].entries.reduce(0) { $0 + $1.value }) * 360
                           
                           Path { path in
                               path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                               path.addArc(
                                   center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                                   radius: min(geometry.size.width, geometry.size.height) / 2,
                                   startAngle: .degrees(startAngle),
                                   endAngle: .degrees(endAngle),
                                   clockwise: false
                               )
                               path.closeSubpath()
                           }
                           .fill(Color.blue.opacity(0.5 + Double(index) * 0.1))
                       }
                   }
               }
               .frame(height: 200)
               .padding(.vertical)
               
               // 圖例
               VStack(alignment: .leading) {
                   ForEach(0..<data.dataSets[0].entries.count, id: \.self) { index in
                       let entry = data.dataSets[0].entries[index]
                       HStack {
                           Rectangle()
                               .fill(Color.blue.opacity(0.5 + Double(index) * 0.1))
                               .frame(width: 20, height: 20)
                           
                           Text(entry.label ?? "")
                               .font(.caption)
                           
                           Spacer()
                           
                           Text("\(Int(entry.value))%")
                               .font(.caption)
                       }
                   }
               }
           }
           .padding()
           .background(
               RoundedRectangle(cornerRadius: 12)
                   .fill(Color(.systemBackground))
                   .shadow(radius: 2)
           )
       }
   }
   ```

**驗證標準**：
- 可視化組件設計統一且美觀
- 組件能夠適應不同的數據和屏幕尺寸
- 組件符合應用的整體設計風格

#### 6.3 在分析結果頁面使用統一的可視化組件

**目標**：在所有分析結果頁面使用統一的可視化組件，確保視覺一致性。

**實施步驟**：

1. 更新睡眠分析結果頁面
   ```swift
   struct SleepAnalysisResultView: View {
       let result: SleepPatternAnalysisResult
       
       var body: some View {
           ScrollView {
               VStack(spacing: 20) {
                   // 使用統一的折線圖組件
                   LineChartView(
                       data: result.toLineChartData(),
                       title: "睡眠質量趨勢",
                       subtitle: "過去14天的睡眠質量變化"
                   )
                   
                   // 使用統一的柱狀圖組件
                   BarChartView(
                       data: result.toBarChartData(),
                       title: "睡眠時長趨勢",
                       subtitle: "過去14天的睡眠時長變化"
                   )
                   
                   // 使用統一的餅圖組件
                   PieChartView(
                       data: result.toPieChartData(),
                       title: "睡眠質量分布",
                       subtitle: "各睡眠質量級別的分布情況"
                   )
                   
                   // 其他內容...
               }
               .padding()
           }
       }
   }
   ```

2. 更新作息分析結果頁面
   ```swift
   struct RoutineAnalysisResultView: View {
       let result: RoutineAnalysisResult
       
       var body: some View {
           ScrollView {
               VStack(spacing: 20) {
                   // 使用統一的可視化組件
                   // ...
               }
               .padding()
           }
       }
   }
   ```

3. 更新預測結果頁面
   ```swift
   struct PredictionResultView: View {
       let result: PredictionResult
       
       var body: some View {
           ScrollView {
               VStack(spacing: 20) {
                   // 使用統一的可視化組件
                   // ...
               }
               .padding()
           }
       }
   }
   ```

**驗證標準**：
- 所有分析結果頁面都使用統一的可視化組件
- 視覺風格一致且符合應用整體設計
- 用戶體驗流暢且直觀

### 7. 添加分析設置界面

#### 7.1 設計分析設置模型

**目標**：設計分析設置模型，支持用戶自定義分析參數。

**實施步驟**：

1. 定義分析設置模型
   ```swift
   struct AnalysisSettings: Codable, Equatable {
       // 通用設置
       var preferLocalAnalysis: Bool = false
       var analysisFrequency: AnalysisFrequency = .daily
       
       // 睡眠分析設置
       var sleepAnalysisSettings = SleepAnalysisSettings()
       
       // 作息分析設置
       var routineAnalysisSettings = RoutineAnalysisSettings()
       
       // 預測設置
       var predictionSettings = PredictionSettings()
   }
   ```

2. 定義分析頻率枚舉
   ```swift
   enum AnalysisFrequency: String, Codable, CaseIterable {
       case realTime = "real_time"
       case hourly = "hourly"
       case daily = "daily"
       case weekly = "weekly"
       
       var displayName: String {
           switch self {
           case .realTime: return "即時分析"
           case .hourly: return "每小時分析"
           case .daily: return "每日分析"
           case .weekly: return "每週分析"
           }
       }
   }
   ```

3. 定義睡眠分析設置
   ```swift
   struct SleepAnalysisSettings: Codable, Equatable {
       var analysisDepth: AnalysisDepth = .comprehensive
       var includeEnvironmentalFactors: Bool = true
       var historicalDataRange: TimeRange = .twoWeeks
   }
   ```

4. 定義分析深度枚舉
   ```swift
   enum AnalysisDepth: String, Codable, CaseIterable {
       case basic = "basic"
       case standard = "standard"
       case comprehensive = "comprehensive"
       
       var displayName: String {
           switch self {
           case .basic: return "基本分析"
           case .standard: return "標準分析"
           case .comprehensive: return "全面分析"
           }
       }
   }
   ```

5. 定義時間範圍枚舉
   ```swift
   enum TimeRange: String, Codable, CaseIterable {
       case oneWeek = "one_week"
       case twoWeeks = "two_weeks"
       case oneMonth = "one_month"
       case threeMonths = "three_months"
       
       var displayName: String {
           switch self {
           case .oneWeek: return "一週"
           case .twoWeeks: return "兩週"
           case .oneMonth: return "一個月"
           case .threeMonths: return "三個月"
           }
       }
       
       var days: Int {
           switch self {
           case .oneWeek: return 7
           case .twoWeeks: return 14
           case .oneMonth: return 30
           case .threeMonths: return 90
           }
       }
   }
   ```

**驗證標準**：
- 分析設置模型設計合理且完整
- 模型支持所有需要的自定義參數
- 模型符合Codable協議，可以序列化和反序列化

#### 7.2 實現設置存儲服務

**目標**：實現設置存儲服務，保存和加載用戶的分析設置。

**實施步驟**：

1. 創建設置存儲服務
   ```swift
   class SettingsService {
       private let userDefaults = UserDefaults.standard
       private let settingsKey = "analysis_settings"
       
       func getAnalysisSettings() -> AnalysisSettings {
           guard let data = userDefaults.data(forKey: settingsKey),
                 let settings = try? JSONDecoder().decode(AnalysisSettings.self, from: data) else {
               return AnalysisSettings() // 返回默認設置
           }
           return settings
       }
       
       func saveAnalysisSettings(_ settings: AnalysisSettings) {
           guard let data = try? JSONEncoder().encode(settings) else { return }
           userDefaults.set(data, forKey: settingsKey)
       }
   }
   ```

2. 在依賴注入容器中註冊設置服務
   ```swift
   container.register(SettingsService.self) { _ in SettingsService() }
   ```

3. 在需要的地方注入設置服務
   ```swift
   class AIEngine {
       private let settingsService: SettingsService
       
       init(sleepUseCase: SleepUseCase, deepseekClient: DeepseekClient, settingsService: SettingsService) {
           self.sleepUseCase = sleepUseCase
           self.deepseekClient = deepseekClient
           self.settingsService = settingsService
       }
       
       func analyzeSleepPattern(for babyId: UUID) -> AnyPublisher<SleepPatternAnalysisResult, AppError> {
           let settings = settingsService.getAnalysisSettings()
           // 根據設置進行分析...
       }
   }
   ```

**驗證標準**：
- 設置存儲服務能夠正確保存和加載設置
- 設置在應用重啟後仍然保持
- 服務能夠處理設置格式變化

#### 7.3 創建分析設置界面

**目標**：創建分析設置界面，允許用戶自定義分析參數。

**實施步驟**：

1. 創建分析設置視圖模型
   ```swift
   class AnalysisSettingsViewModel: ObservableObject {
       @Published var settings: AnalysisSettings
       private let settingsService: SettingsService
       
       init(settingsService: SettingsService) {
           self.settingsService = settingsService
           self.settings = settingsService.getAnalysisSettings()
       }
       
       func saveSettings() {
           settingsService.saveAnalysisSettings(settings)
       }
   }
   ```

2. 創建分析設置視圖
   ```swift
   struct AnalysisSettingsView: View {
       @StateObject private var viewModel: AnalysisSettingsViewModel
       @Environment(\.presentationMode) var presentationMode
       
       init(settingsService: SettingsService) {
           _viewModel = StateObject(wrappedValue: AnalysisSettingsViewModel(settingsService: settingsService))
       }
       
       var body: some View {
           NavigationView {
               Form {
                   // 通用設置
                   Section(header: Text("通用設置")) {
                       Toggle("優先使用本地分析", isOn: $viewModel.settings.preferLocalAnalysis)
                       
                       Picker("分析頻率", selection: $viewModel.settings.analysisFrequency) {
                           ForEach(AnalysisFrequency.allCases, id: \.self) { frequency in
                               Text(frequency.displayName).tag(frequency)
                           }
                       }
                   }
                   
                   // 睡眠分析設置
                   Section(header: Text("睡眠分析設置")) {
                       Picker("分析深度", selection: $viewModel.settings.sleepAnalysisSettings.analysisDepth) {
                           ForEach(AnalysisDepth.allCases, id: \.self) { depth in
                               Text(depth.displayName).tag(depth)
                           }
                       }
                       
                       Toggle("包含環境因素分析", isOn: $viewModel.settings.sleepAnalysisSettings.includeEnvironmentalFactors)
                       
                       Picker("歷史數據範圍", selection: $viewModel.settings.sleepAnalysisSettings.historicalDataRange) {
                           ForEach(TimeRange.allCases, id: \.self) { range in
                               Text(range.displayName).tag(range)
                           }
                       }
                   }
                   
                   // 作息分析設置
                   Section(header: Text("作息分析設置")) {
                       // 類似的設置項...
                   }
                   
                   // 預測設置
                   Section(header: Text("預測設置")) {
                       // 類似的設置項...
                   }
               }
               .navigationTitle("分析設置")
               .navigationBarItems(
                   leading: Button("取消") {
                       presentationMode.wrappedValue.dismiss()
                   },
                   trailing: Button("保存") {
                       viewModel.saveSettings()
                       presentationMode.wrappedValue.dismiss()
                   }
               )
           }
       }
   }
   ```

**驗證標準**：
- 分析設置界面設計合理且美觀
- 所有設置項都能正確顯示和編輯
- 設置變更能夠正確保存

#### 7.4 在主界面添加設置入口

**目標**：在主界面添加設置入口，方便用戶訪問分析設置。

**實施步驟**：

1. 在分析頁面添加設置按鈕
   ```swift
   struct SleepAnalysisView: View {
       @ObservedObject var viewModel: SleepAnalysisViewModel
       @State private var showingSettings = false
       @EnvironmentObject var networkMonitor: NetworkMonitor
       @EnvironmentObject var settingsService: SettingsService
       
       var body: some View {
           VStack {
               // 現有UI...
               
               // 添加設置按鈕
               HStack {
                   Spacer()
                   
                   Button(action: {
                       showingSettings = true
                   }) {
                       Image(systemName: "gear")
                           .font(.system(size: 20))
                           .foregroundColor(.primary)
                           .padding(8)
                           .background(
                               Circle()
                                   .fill(Color(.systemBackground))
                                   .shadow(radius: 2)
                           )
                   }
                   .padding()
               }
           }
           .sheet(isPresented: $showingSettings) {
               AnalysisSettingsView(settingsService: settingsService)
           }
       }
   }
   ```

2. 在其他分析頁面添加類似的設置入口

**驗證標準**：
- 設置入口位置合理且易於訪問
- 點擊設置按鈕能夠正確打開設置界面
- 設置變更後能夠立即影響分析行為

### 8. 改進分析過程透明度

#### 8.1 設計分析進度模型

**目標**：設計分析進度模型，支持顯示分析過程的詳細進度。

**實施步驟**：

1. 定義分析階段枚舉
   ```swift
   enum AnalysisStage: String, CaseIterable {
       case dataLoading = "data_loading"
       case preprocessing = "preprocessing"
       case patternAnalysis = "pattern_analysis"
       case environmentalAnalysis = "environmental_analysis"
       case qualityEvaluation = "quality_evaluation"
       case recommendationGeneration = "recommendation_generation"
       case finalizing = "finalizing"
       
       var displayName: String {
           switch self {
           case .dataLoading: return "加載數據"
           case .preprocessing: return "數據預處理"
           case .patternAnalysis: return "模式分析"
           case .environmentalAnalysis: return "環境因素分析"
           case .qualityEvaluation: return "質量評估"
           case .recommendationGeneration: return "生成建議"
           case .finalizing: return "完成分析"
           }
       }
       
       var description: String {
           switch self {
           case .dataLoading: return "正在加載寶寶的睡眠記錄數據..."
           case .preprocessing: return "正在清理和準備數據進行分析..."
           case .patternAnalysis: return "正在識別睡眠模式和週期..."
           case .environmentalAnalysis: return "正在分析環境因素對睡眠的影響..."
           case .qualityEvaluation: return "正在評估整體睡眠質量..."
           case .recommendationGeneration: return "正在基於分析結果生成個性化建議..."
           case .finalizing: return "正在完成分析並準備結果..."
           }
       }
   }
   ```

2. 定義分析進度結構體
   ```swift
   struct AnalysisProgress {
       let stage: AnalysisStage
       let progress: Double // 0.0 - 1.0
       let message: String?
       
       init(stage: AnalysisStage, progress: Double, message: String? = nil) {
           self.stage = stage
           self.progress = progress
           self.message = message
       }
   }
   ```

**驗證標準**：
- 分析進度模型設計合理且完整
- 模型支持顯示所有分析階段的進度
- 模型提供足夠的上下文信息

#### 8.2 在AIEngine中添加進度報告

**目標**：在AIEngine中添加進度報告機制，實時報告分析進度。

**實施步驟**：

1. 在AIEngine中添加進度報告回調
   ```swift
   class AIEngine {
       // 進度報告回調
       var onProgressUpdate: ((AnalysisProgress) -> Void)?
       
       // 其他屬性和方法...
   }
   ```

2. 在分析過程中報告進度
   ```swift
   func analyzeSleepPattern(for babyId: UUID) -> AnyPublisher<SleepPatternAnalysisResult, AppError> {
       return Future<SleepPatternAnalysisResult, AppError> { [weak self] promise in
           // 報告進度：數據加載
           self?.onProgressUpdate?(AnalysisProgress(
               stage: .dataLoading,
               progress: 0.0
           ))
           
           // 加載數據...
           
           // 報告進度：數據加載完成
           self?.onProgressUpdate?(AnalysisProgress(
               stage: .dataLoading,
               progress: 1.0
           ))
           
           // 報告進度：數據預處理
           self?.onProgressUpdate?(AnalysisProgress(
               stage: .preprocessing,
               progress: 0.0
           ))
           
           // 預處理數據...
           
           // 報告進度：數據預處理完成
           self?.onProgressUpdate?(AnalysisProgress(
               stage: .preprocessing,
               progress: 1.0
           ))
           
           // 報告進度：模式分析
           self?.onProgressUpdate?(AnalysisProgress(
               stage: .patternAnalysis,
               progress: 0.0
           ))
           
           // 模式分析...
           
           // 報告進度：模式分析完成
           self?.onProgressUpdate?(AnalysisProgress(
               stage: .patternAnalysis,
               progress: 1.0
           ))
           
           // 其他階段...
           
           // 報告進度：完成
           self?.onProgressUpdate?(AnalysisProgress(
               stage: .finalizing,
               progress: 1.0
           ))
           
           // 返回結果
           promise(.success(result))
       }
       .eraseToAnyPublisher()
   }
   ```

3. 在DeepseekClient中也添加類似的進度報告

**驗證標準**：
- AIEngine能夠在分析過程中報告進度
- 進度報告包含當前階段、進度百分比和描述信息
- 進度報告及時且準確

#### 8.3 創建進度展示UI組件

**目標**：創建進度展示UI組件，以用戶友好的方式顯示分析進度。

**實施步驟**：

1. 創建分析進度視圖
   ```swift
   struct AnalysisProgressView: View {
       let progress: AnalysisProgress
       
       var body: some View {
           VStack(spacing: 16) {
               Text(progress.stage.displayName)
                   .font(.headline)
               
               Text(progress.stage.description)
                   .font(.subheadline)
                   .multilineTextAlignment(.center)
                   .padding(.horizontal)
               
               ProgressView(value: progress.progress)
                   .progressViewStyle(LinearProgressViewStyle())
                   .padding(.horizontal)
               
               if let message = progress.message {
                   Text(message)
                       .font(.caption)
                       .foregroundColor(.secondary)
               }
           }
           .padding()
           .background(
               RoundedRectangle(cornerRadius: 12)
                   .fill(Color(.systemBackground))
                   .shadow(radius: 4)
           )
           .padding()
       }
   }
   ```

2. 創建分析階段指示器
   ```swift
   struct AnalysisStageIndicator: View {
       let currentStage: AnalysisStage
       
       var body: some View {
           VStack(spacing: 8) {
               HStack {
                   ForEach(AnalysisStage.allCases, id: \.self) { stage in
                       Circle()
                           .fill(stageColor(stage))
                           .frame(width: 12, height: 12)
                       
                       if stage != AnalysisStage.allCases.last {
                           Rectangle()
                               .fill(stageLineColor(stage))
                               .frame(height: 2)
                       }
                   }
               }
               
               Text(currentStage.displayName)
                   .font(.caption)
                   .foregroundColor(.primary)
           }
           .padding(.horizontal)
       }
       
       private func stageColor(_ stage: AnalysisStage) -> Color {
           let currentIndex = AnalysisStage.allCases.firstIndex(of: currentStage) ?? 0
           let stageIndex = AnalysisStage.allCases.firstIndex(of: stage) ?? 0
           
           if stageIndex < currentIndex {
               return .green // 已完成
           } else if stageIndex == currentIndex {
               return .blue // 當前
           } else {
               return .gray.opacity(0.3) // 未開始
           }
       }
       
       private func stageLineColor(_ stage: AnalysisStage) -> Color {
           let currentIndex = AnalysisStage.allCases.firstIndex(of: currentStage) ?? 0
           let stageIndex = AnalysisStage.allCases.firstIndex(of: stage) ?? 0
           
           if stageIndex < currentIndex {
               return .green // 已完成
           } else {
               return .gray.opacity(0.3) // 未開始或當前
           }
       }
   }
   ```

**驗證標準**：
- 進度展示UI組件設計合理且美觀
- 組件能夠清晰顯示當前分析階段和進度
- 組件提供足夠的上下文信息

#### 8.4 在分析頁面集成進度展示

**目標**：在分析頁面集成進度展示，提高分析過程的透明度。

**實施步驟**：

1. 在視圖模型中添加進度狀態
   ```swift
   class SleepAnalysisViewModel: ObservableObject {
       @Published var analysisResult: SleepPatternAnalysisResult?
       @Published var isLoading = false
       @Published var error: AppError?
       @Published var progress: AnalysisProgress?
       
       private let aiEngine: AIEngine
       private var cancellables = Set<AnyCancellable>()
       
       init(aiEngine: AIEngine) {
           self.aiEngine = aiEngine
           
           // 設置進度報告回調
           aiEngine.onProgressUpdate = { [weak self] progress in
               DispatchQueue.main.async {
                   self?.progress = progress
               }
           }
       }
       
       func analyzeSleepPattern(for babyId: UUID) {
           isLoading = true
           error = nil
           progress = nil
           
           aiEngine.analyzeSleepPatternPublisher(for: babyId)
               .receive(on: DispatchQueue.main)
               .sink(
                   receiveCompletion: { [weak self] completion in
                       self?.isLoading = false
                       if case .failure(let error) = completion {
                           self?.error = error
                       }
                       self?.progress = nil
                   },
                   receiveValue: { [weak self] result in
                       self?.analysisResult = result
                   }
               )
               .store(in: &cancellables)
       }
   }
   ```

2. 在分析頁面顯示進度
   ```swift
   struct SleepAnalysisView: View {
       @ObservedObject var viewModel: SleepAnalysisViewModel
       @EnvironmentObject var networkMonitor: NetworkMonitor
       
       var body: some View {
           VStack {
               if !networkMonitor.isConnected {
                   OfflineBanner(analysisType: .sleep)
               }
               
               if viewModel.isLoading {
                   if let progress = viewModel.progress {
                       VStack {
                           AnalysisStageIndicator(currentStage: progress.stage)
                               .padding(.bottom)
                           
                           AnalysisProgressView(progress: progress)
                       }
                   } else {
                       ProgressView("準備分析...")
                   }
               } else if let error = viewModel.error {
                   ErrorView(error: error, retryAction: {
                       viewModel.retry()
                   })
               } else if let result = viewModel.analysisResult {
                   SleepAnalysisResultView(result: result)
               } else {
                   Text("請選擇寶寶並開始分析")
               }
           }
       }
   }
   ```

**驗證標準**：
- 分析頁面能夠顯示分析進度
- 進度展示清晰且用戶友好
- 用戶能夠了解分析過程中發生了什麼

## 實施時間規劃

### 第一週：高優先級改進

1. **依賴方向衝突修復**（2天）
   - 第1天：AIEngine重構，確保通過UseCase層訪問數據
   - 第2天：明確依賴關係，更新依賴注入配置

2. **異步處理模式統一**（2天）
   - 第3天：統一使用Combine，為回調接口添加適配器
   - 第4天：統一錯誤類型，更新所有使用異步接口的代碼

3. **完善錯誤處理**（2天）
   - 第5天：統一使用Result類型，完善錯誤傳播機制
   - 第6天：添加用戶友好的錯誤展示

4. **添加離線模式提示**（1天）
   - 第7天：優化網絡狀態監控，添加離線模式UI提示，實現功能可用性動態調整

### 第二週：中優先級改進

5. **統一數據轉換方式**（2天）
   - 第8天：創建統一的映射協議，為所有模型實現映射協議
   - 第9天：在視圖模型中統一使用映射函數

6. **優化可視化整合**（2天）
   - 第10天：重構可視化組件，提高復用性
   - 第11天：創建統一的可視化組件，在分析結果頁面使用統一的可視化組件

7. **添加分析設置界面**（2天）
   - 第12天：設計分析設置模型，實現設置存儲服務
   - 第13天：創建分析設置界面，在主界面添加設置入口

8. **改進分析過程透明度**（1天）
   - 第14天：設計分析進度模型，在AIEngine中添加進度報告，創建進度展示UI組件，在分析頁面集成進度展示

### 第三週：測試與優化

9. **單元測試**（2天）
   - 第15-16天：為所有改進項目編寫單元測試

10. **集成測試**（2天）
    - 第17-18天：進行集成測試，確保所有組件協同工作

11. **UI測試**（1天）
    - 第19天：進行UI測試，確保用戶界面正常工作

12. **性能優化**（1天）
    - 第20天：進行性能優化，確保應用運行流暢

13. **文檔更新**（1天）
    - 第21天：更新所有相關文檔，記錄改進內容和測試結果

## 驗證計劃

### 單元測試

1. **依賴方向測試**
   - 測試AIEngine是否通過UseCase層訪問數據
   - 測試依賴關係是否清晰且無循環

2. **異步處理測試**
   - 測試Combine適配器是否正常工作
   - 測試錯誤類型轉換是否正確

3. **錯誤處理測試**
   - 測試Result類型是否正確使用
   - 測試錯誤傳播機制是否完整

4. **離線模式測試**
   - 測試網絡狀態監控是否準確
   - 測試功能可用性動態調整是否正確

5. **數據轉換測試**
   - 測試映射協議實現是否正確
   - 測試視圖模型中的數據轉換是否一致

6. **可視化組件測試**
   - 測試可視化組件是否正確顯示數據
   - 測試組件在不同屏幕尺寸下的表現

7. **設置界面測試**
   - 測試設置存儲服務是否正確保存和加載設置
   - 測試設置變更是否影響分析行為

8. **進度展示測試**
   - 測試進度報告機制是否正常工作
   - 測試進度展示UI是否正確顯示進度

### 集成測試

1. **依賴注入測試**
   - 測試所有組件是否能夠正確解析其依賴
   - 測試應用啟動和運行是否正常

2. **數據流測試**
   - 測試從數據加載到UI顯示的完整流程
   - 測試用戶操作觸發的數據更新流程

3. **錯誤處理流程測試**
   - 測試各種錯誤情況下的完整處理流程
   - 測試錯誤恢復機制是否正常工作

4. **網絡狀態變化測試**
   - 測試網絡連接和斷開時的應用行為
   - 測試網絡狀態變化時的UI更新

### UI測試

1. **錯誤展示測試**
   - 測試各種錯誤情況下的UI展示
   - 測試錯誤恢復操作是否正常工作

2. **離線模式UI測試**
   - 測試離線模式下的UI提示
   - 測試功能可用性變化時的UI更新

3. **設置界面測試**
   - 測試設置界面的所有交互
   - 測試設置變更後的UI更新

4. **進度展示測試**
   - 測試分析過程中的進度展示
   - 測試不同分析階段的UI更新

## 預期成果

1. **架構一致性提高**
   - 所有組件遵循相同的架構原則
   - 依賴關係清晰且無循環
   - 代碼更易於理解和維護

2. **異步處理統一**
   - 所有異步操作使用Combine框架
   - 錯誤處理機制統一且完整
   - 代碼更簡潔且易於測試

3. **錯誤處理完善**
   - 所有錯誤都能正確傳播到UI層
   - 錯誤信息清晰且用戶友好
   - 提供錯誤恢復機制

4. **離線體驗改善**
   - 明確提示離線模式下的功能限制
   - 動態調整功能可用性
   - 提供平滑的離線到在線過渡

5. **數據轉換一致**
   - 所有數據轉換使用統一的映射函數
   - 轉換邏輯集中且易於測試
   - 代碼更簡潔且易於維護

6. **可視化體驗統一**
   - 所有分析結果使用統一的可視化組件
   - 視覺風格一致且符合應用整體設計
   - 用戶體驗流暢且直觀

7. **用戶控制力提升**
   - 提供分析設置界面，允許用戶自定義分析參數
   - 設置變更立即影響分析行為
   - 用戶能夠根據自己的需求調整分析

8. **分析透明度提高**
   - 顯示分析過程的詳細進度
   - 提供足夠的上下文信息
   - 用戶能夠了解分析過程中發生了什麼

## 結論

本實施方案詳細說明了「寶寶生活記錄專業版（Baby Tracker）」iOS應用中第三階段與前兩階段整合的具體改進項目、實施步驟、驗證標準和時間規劃。通過實施這些改進，我們將顯著提高應用的架構一致性、代碼質量、用戶體驗和功能完整性，為用戶提供更加穩定、流暢和功能豐富的育兒助手。
