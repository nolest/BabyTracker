# 寶寶生活記錄專業版（Baby Tracker）- 高優先級整合改進

## 概述

本文檔詳細說明「寶寶生活記錄專業版（Baby Tracker）」iOS應用中第三階段與前兩階段整合的高優先級改進項目，包括依賴方向衝突修復、異步處理模式統一、錯誤處理完善和離線模式提示等。

## 1. 依賴方向衝突修復

### 問題描述

在整合驗證中發現，第三階段的AI引擎部分直接訪問Repository層，違反了前兩階段建立的MVVM架構原則。此外，DeepseekClient與AIEngine之間的依賴關係不清晰，存在潛在的循環依賴風險。

### 解決方案

#### 1.1 AIEngine重構

```swift
// 修改前：AIEngine直接訪問Repository
class AIEngine {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func analyzeSleepPattern(for babyId: UUID) -> SleepPatternAnalysisResult {
        // 直接從Repository獲取數據
        let sleepRecords = sleepRepository.getSleepRecords(for: babyId)
        // 分析邏輯...
    }
}

// 修改後：AIEngine通過UseCase層訪問數據
class AIEngine {
    private let sleepUseCase: SleepUseCase
    
    init(sleepUseCase: SleepUseCase) {
        self.sleepUseCase = sleepUseCase
    }
    
    func analyzeSleepPattern(for babyId: UUID) -> SleepPatternAnalysisResult {
        // 通過UseCase獲取數據
        let sleepRecords = sleepUseCase.getSleepRecords(for: babyId)
        // 分析邏輯...
    }
}
```

#### 1.2 明確依賴關係

```swift
// 修改前：依賴關係不清晰
class DeepseekClient {
    var aiEngine: AIEngine?
    // ...
}

class AIEngine {
    var deepseekClient: DeepseekClient?
    // ...
}

// 修改後：明確單向依賴
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

#### 1.3 依賴注入重構

```swift
// 修改前：直接創建依賴
class SleepAnalysisViewModel {
    private let aiEngine = AIEngine(sleepRepository: SleepRepository())
    // ...
}

// 修改後：通過依賴注入
class SleepAnalysisViewModel {
    private let aiEngine: AIEngine
    
    init(aiEngine: AIEngine) {
        self.aiEngine = aiEngine
    }
    // ...
}

// 在DI容器中配置
container.register(SleepRepository.self) { _ in SleepRepositoryImpl() }
container.register(SleepUseCase.self) { r in SleepUseCaseImpl(repository: r.resolve(SleepRepository.self)!) }
container.register(DeepseekClient.self) { _ in DeepseekClientImpl() }
container.register(AIEngine.self) { r in 
    AIEngine(
        sleepUseCase: r.resolve(SleepUseCase.self)!,
        deepseekClient: r.resolve(DeepseekClient.self)!
    )
}
container.register(SleepAnalysisViewModel.self) { r in 
    SleepAnalysisViewModel(aiEngine: r.resolve(AIEngine.self)!)
}
```

## 2. 異步處理模式統一

### 問題描述

第一、二階段使用回調和Combine混合的方式處理異步操作，而第三階段主要使用Combine，導致部分接口不兼容，增加了集成難度和維護成本。

### 解決方案

#### 2.1 統一使用Combine

```swift
// 修改前：使用回調
func getSleepRecords(for babyId: UUID, completion: @escaping ([SleepRecord]) -> Void) {
    // 實現...
}

// 修改後：使用Combine
func getSleepRecords(for babyId: UUID) -> AnyPublisher<[SleepRecord], Error> {
    // 實現...
}
```

#### 2.2 為回調接口添加Combine適配器

```swift
// 為現有回調接口添加Combine包裝
extension SleepRepository {
    // 原有回調方法保持不變
    func getSleepRecords(for babyId: UUID, completion: @escaping ([SleepRecord]) -> Void) {
        // 原有實現...
    }
    
    // 添加Combine包裝
    func getSleepRecordsPublisher(for babyId: UUID) -> AnyPublisher<[SleepRecord], Error> {
        return Future<[SleepRecord], Error> { promise in
            self.getSleepRecords(for: babyId) { records in
                promise(.success(records))
            }
        }.eraseToAnyPublisher()
    }
}
```

#### 2.3 統一錯誤類型

```swift
// 定義統一的錯誤類型
enum AppError: Error {
    case network(NetworkError)
    case database(DatabaseError)
    case analysis(AnalysisError)
    case unknown(Error)
}

// 在所有Publisher中使用統一的錯誤類型
func getSleepRecordsPublisher(for babyId: UUID) -> AnyPublisher<[SleepRecord], AppError> {
    return originalPublisher
        .mapError { error in
            if let networkError = error as? NetworkError {
                return .network(networkError)
            } else if let dbError = error as? DatabaseError {
                return .database(dbError)
            } else {
                return .unknown(error)
            }
        }
        .eraseToAnyPublisher()
}
```

## 3. 完善錯誤處理

### 問題描述

第三階段的AI分析錯誤未能完全傳播到UI層，導致用戶無法看到詳細錯誤信息。此外，錯誤處理方式與前兩階段不一致，增加了維護難度。

### 解決方案

#### 3.1 統一使用Result類型

```swift
// 修改前：直接拋出錯誤
func analyzeSleepPattern(for babyId: UUID) throws -> SleepPatternAnalysisResult {
    // 實現...
}

// 修改後：使用Result類型
func analyzeSleepPattern(for babyId: UUID) -> Result<SleepPatternAnalysisResult, AppError> {
    // 實現...
}
```

#### 3.2 完善錯誤傳播機制

```swift
// 在ViewModel中處理錯誤並更新UI狀態
class SleepAnalysisViewModel: ObservableObject {
    @Published var analysisResult: SleepPatternAnalysisResult?
    @Published var isLoading = false
    @Published var error: AppError?
    
    private let aiEngine: AIEngine
    private var cancellables = Set<AnyCancellable>()
    
    init(aiEngine: AIEngine) {
        self.aiEngine = aiEngine
    }
    
    func analyzeSleepPattern(for babyId: UUID) {
        isLoading = true
        error = nil
        
        aiEngine.analyzeSleepPattern(for: babyId)
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
}
```

#### 3.3 用戶友好的錯誤展示

```swift
// 在View中展示錯誤
struct SleepAnalysisView: View {
    @ObservedObject var viewModel: SleepAnalysisViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("分析中...")
            } else if let error = viewModel.error {
                ErrorView(error: error, retryAction: {
                    viewModel.analyzeSleepPattern(for: selectedBabyId)
                })
            } else if let result = viewModel.analysisResult {
                SleepAnalysisResultView(result: result)
            } else {
                Text("請選擇寶寶並開始分析")
            }
        }
    }
}

// 統一的錯誤展示組件
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

## 4. 添加離線模式提示

### 問題描述

當前在離線模式下，部分高級分析功能不可用，但系統未明確提示用戶，導致用戶體驗不佳。

### 解決方案

#### 4.1 網絡狀態監控優化

```swift
// 優化網絡監控，添加更多狀態
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
    
    // 實現...
}
```

#### 4.2 離線模式UI提示

```swift
// 在分析頁面添加離線模式提示
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

// 離線模式提示橫幅
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

#### 4.3 功能可用性動態調整

```swift
// 根據網絡狀態動態調整功能可用性
class SleepAnalysisViewModel: ObservableObject {
    @Published var availableAnalysisTypes: [AnalysisType] = []
    private let networkMonitor: NetworkMonitor
    
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
    }
    
    private func updateAvailableAnalysisTypes(isConnected: Bool) {
        if isConnected {
            // 在線模式：所有分析類型可用
            availableAnalysisTypes = [.basic, .advanced, .environmental]
        } else {
            // 離線模式：僅基本分析可用
            availableAnalysisTypes = [.basic]
        }
    }
}

// 在UI中反映功能可用性
struct AnalysisTypeSelector: View {
    @ObservedObject var viewModel: SleepAnalysisViewModel
    @Binding var selectedType: AnalysisType
    
    var body: some View {
        Picker("分析類型", selection: $selectedType) {
            ForEach(viewModel.availableAnalysisTypes, id: \.self) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.availableAnalysisTypes) { newTypes in
            if !newTypes.contains(selectedType) {
                selectedType = newTypes.first ?? .basic
            }
        }
    }
}
```

## 實施計劃

1. **依賴方向衝突修復**
   - 重構AIEngine，確保通過UseCase層訪問數據
   - 明確DeepseekClient與AIEngine之間的依賴關係
   - 更新依賴注入配置

2. **異步處理模式統一**
   - 為關鍵接口添加Combine包裝
   - 統一錯誤類型
   - 更新所有使用異步接口的代碼

3. **完善錯誤處理**
   - 統一使用Result類型
   - 實現完整的錯誤傳播機制
   - 添加用戶友好的錯誤展示組件

4. **添加離線模式提示**
   - 優化網絡狀態監控
   - 添加離線模式UI提示
   - 實現功能可用性動態調整

## 測試計劃

1. **單元測試**
   - 測試重構後的AIEngine
   - 測試異步接口的Combine包裝
   - 測試錯誤處理機制

2. **集成測試**
   - 測試依賴注入配置
   - 測試異步操作流程
   - 測試錯誤傳播機制

3. **UI測試**
   - 測試錯誤展示組件
   - 測試離線模式提示
   - 測試功能可用性動態調整

## 預期成果

1. 系統架構一致性提高，所有組件遵循相同的架構原則
2. 異步處理模式統一，降低維護成本
3. 錯誤處理機制完善，提高系統穩定性和用戶體驗
4. 離線模式下用戶體驗改善，功能可用性更加透明
