# 寶寶生活記錄專業版（Baby Tracker）- 統一錯誤處理機制

## 1. 問題描述

在第一階段與第二階段整合性驗證中，發現錯誤處理機制不一致的問題。第一階段使用Result類型和錯誤枚舉進行錯誤處理，而第二階段部分地方直接使用可選綁定或簡單的錯誤打印，缺乏統一的錯誤處理和展示策略。這種不一致性會導致以下問題：

1. 用戶體驗不一致，有些錯誤得到適當處理和提示，有些則被忽略
2. 開發者難以追蹤和診斷問題，因為錯誤處理分散且不統一
3. 代碼可維護性降低，因為不同部分使用不同的錯誤處理方式
4. 錯誤信息不夠友好，用戶難以理解問題並採取適當行動

## 2. 修正方案

### 2.1 定義統一的錯誤類型

首先，需要定義一個統一的應用錯誤類型，涵蓋所有可能的錯誤情況：

```swift
// AppError.swift

enum AppError: Error, Identifiable {
    // 網絡相關錯誤
    case networkError(String)
    
    // 數據相關錯誤
    case dataError(String)
    case entityNotFound(String)
    case invalidData(String)
    
    // 用戶輸入相關錯誤
    case validationError(String)
    case inputError(String)
    
    // 應用狀態相關錯誤
    case stateError(String)
    case permissionDenied(String)
    
    // 未知錯誤
    case unknownError(String)
    
    // 實現Identifiable協議
    var id: String {
        switch self {
        case .networkError(let message): return "network_\(message)"
        case .dataError(let message): return "data_\(message)"
        case .entityNotFound(let message): return "notFound_\(message)"
        case .invalidData(let message): return "invalid_\(message)"
        case .validationError(let message): return "validation_\(message)"
        case .inputError(let message): return "input_\(message)"
        case .stateError(let message): return "state_\(message)"
        case .permissionDenied(let message): return "permission_\(message)"
        case .unknownError(let message): return "unknown_\(message)"
        }
    }
    
    // 用戶友好的錯誤消息
    var userMessage: String {
        switch self {
        case .networkError(let message): return "網絡連接問題：\(message)"
        case .dataError(let message): return "數據處理問題：\(message)"
        case .entityNotFound(let message): return "找不到數據：\(message)"
        case .invalidData(let message): return "數據無效：\(message)"
        case .validationError(let message): return "驗證失敗：\(message)"
        case .inputError(let message): return "輸入錯誤：\(message)"
        case .stateError(let message): return "應用狀態錯誤：\(message)"
        case .permissionDenied(let message): return "權限不足：\(message)"
        case .unknownError(let message): return "未知錯誤：\(message)"
        }
    }
    
    // 錯誤圖標
    var iconName: String {
        switch self {
        case .networkError: return "wifi.slash"
        case .dataError, .entityNotFound, .invalidData: return "exclamationmark.triangle"
        case .validationError, .inputError: return "exclamationmark.circle"
        case .stateError: return "gearshape.2"
        case .permissionDenied: return "lock.shield"
        case .unknownError: return "questionmark.circle"
        }
    }
    
    // 錯誤嚴重程度
    enum Severity {
        case low, medium, high
    }
    
    var severity: Severity {
        switch self {
        case .inputError, .validationError:
            return .low
        case .networkError, .entityNotFound, .stateError:
            return .medium
        case .dataError, .invalidData, .permissionDenied, .unknownError:
            return .high
        }
    }
}

// 擴展Error協議，處理非AppError類型
extension Error {
    var asAppError: AppError {
        if let appError = self as? AppError {
            return appError
        } else {
            return .unknownError(localizedDescription)
        }
    }
}
```

### 2.2 實現錯誤處理服務

接下來，實現一個全局的錯誤處理服務，負責處理和展示錯誤：

```swift
// ErrorHandlingService.swift

class ErrorHandlingService: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    // 處理錯誤
    func handle(_ error: Error) {
        let appError = error.asAppError
        
        // 記錄錯誤
        logError(appError)
        
        // 設置當前錯誤並顯示
        DispatchQueue.main.async { [weak self] in
            self?.currentError = appError
            self?.showingError = true
        }
    }
    
    // 處理錯誤並執行回調
    func handle(_ error: Error, completion: @escaping () -> Void) {
        handle(error)
        completion()
    }
    
    // 處理Result類型
    func handleResult<T>(_ result: Result<T, Error>, onSuccess: @escaping (T) -> Void) {
        switch result {
        case .success(let value):
            onSuccess(value)
        case .failure(let error):
            handle(error)
        }
    }
    
    // 關閉錯誤提示
    func dismiss() {
        DispatchQueue.main.async { [weak self] in
            self?.showingError = false
            self?.currentError = nil
        }
    }
    
    // 記錄錯誤
    private func logError(_ error: AppError) {
        // 在實際應用中，這裡可以將錯誤發送到日誌服務
        print("ERROR: \(error.userMessage)")
    }
}
```

### 2.3 創建錯誤展示視圖

創建一個通用的錯誤展示視圖，用於在UI中顯示錯誤：

```swift
// ErrorView.swift

struct ErrorView: View {
    let error: AppError
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: error.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(error.userMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: error)
    }
    
    private var errorTitle: String {
        switch error.severity {
        case .low:
            return "注意"
        case .medium:
            return "警告"
        case .high:
            return "錯誤"
        }
    }
    
    private var backgroundColor: Color {
        switch error.severity {
        case .low:
            return Color.blue
        case .medium:
            return Color.orange
        case .high:
            return Color.red
        }
    }
}
```

### 2.4 創建全局錯誤處理修飾器

創建一個SwiftUI視圖修飾器，用於在任何視圖中顯示錯誤：

```swift
// ErrorHandlingModifier.swift

struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandlingService
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if errorHandler.showingError, let error = errorHandler.currentError {
                VStack {
                    Spacer()
                    ErrorView(error: error) {
                        errorHandler.dismiss()
                    }
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: errorHandler.showingError)
                .zIndex(100)
            }
        }
    }
}

// 擴展View協議，方便使用
extension View {
    func handleErrors(with errorHandler: ErrorHandlingService) -> some View {
        self.modifier(ErrorHandlingModifier(errorHandler: errorHandler))
    }
}
```

### 2.5 在Repository層統一錯誤處理

修改Repository實現，使用統一的錯誤類型：

```swift
// BabyRepositoryImpl.swift

class BabyRepositoryImpl: BabyRepository {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    func getAllBabies(completion: @escaping (Result<[Baby], Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<BabyEntity> = BabyEntity.fetchRequest()
        
        do {
            let babyEntities = try context.fetch(fetchRequest)
            let babies = babyEntities.map { $0.toDomain() }
            completion(.success(babies))
        } catch {
            // 轉換為應用錯誤類型
            let appError = AppError.dataError("無法獲取寶寶列表：\(error.localizedDescription)")
            completion(.failure(appError))
        }
    }
    
    func getBaby(id: UUID, completion: @escaping (Result<Baby, Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<BabyEntity> = BabyEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let babyEntity = results.first {
                let baby = babyEntity.toDomain()
                completion(.success(baby))
            } else {
                // 使用應用錯誤類型
                let appError = AppError.entityNotFound("找不到ID為\(id)的寶寶")
                completion(.failure(appError))
            }
        } catch {
            // 轉換為應用錯誤類型
            let appError = AppError.dataError("獲取寶寶時出錯：\(error.localizedDescription)")
            completion(.failure(appError))
        }
    }
    
    // 其他方法類似修改...
}
```

### 2.6 在UseCase層統一錯誤處理

確保UseCase層正確傳遞錯誤：

```swift
// GetBabiesUseCase.swift

class GetBabiesUseCase {
    private let babyRepository: BabyRepository
    
    init(babyRepository: BabyRepository) {
        self.babyRepository = babyRepository
    }
    
    func execute(completion: @escaping (Result<[Baby], Error>) -> Void) {
        babyRepository.getAllBabies { result in
            switch result {
            case .success(let babies):
                completion(.success(babies))
            case .failure(let error):
                // 直接傳遞錯誤，保持錯誤類型
                completion(.failure(error))
            }
        }
    }
}
```

### 2.7 在ViewModel層統一錯誤處理

修改ViewModel，使用錯誤處理服務：

```swift
// BabySelectorViewModel.swift

class BabySelectorViewModel: ObservableObject {
    @Published var babies: [BabyViewModel] = []
    @Published var selectedBabyId: UUID?
    @Published var isLoading: Bool = false
    
    private let getBabiesUseCase: GetBabiesUseCase
    private let errorHandler: ErrorHandlingService
    
    init(getBabiesUseCase: GetBabiesUseCase, errorHandler: ErrorHandlingService) {
        self.getBabiesUseCase = getBabiesUseCase
        self.errorHandler = errorHandler
        loadBabies()
    }
    
    func loadBabies() {
        isLoading = true
        
        getBabiesUseCase.execute { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                // 使用錯誤處理服務處理結果
                self.errorHandler.handleResult(result) { babies in
                    self.babies = babies.map { BabyViewModel(baby: $0) }
                    if let firstBaby = babies.first {
                        self.selectedBabyId = firstBaby.id
                    }
                }
            }
        }
    }
    
    func selectBaby(id: UUID) {
        selectedBabyId = id
    }
}
```

### 2.8 在UI層統一錯誤處理

在UI層使用錯誤處理修飾器：

```swift
// BabySelectorView.swift

struct BabySelectorView: View {
    @ObservedObject var viewModel: BabySelectorViewModel
    @EnvironmentObject var errorHandler: ErrorHandlingService
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("載入中...")
            } else {
                if viewModel.babies.isEmpty {
                    Text("沒有寶寶記錄")
                        .foregroundColor(.secondary)
                } else {
                    // 寶寶選擇器UI
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.babies) { babyVM in
                                BabyAvatarView(baby: babyVM, isSelected: babyVM.id == viewModel.selectedBabyId)
                                    .onTapGesture {
                                        viewModel.selectBaby(id: babyVM.id)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .handleErrors(with: errorHandler) // 使用錯誤處理修飾器
    }
}
```

### 2.9 更新依賴注入

更新依賴注入容器，添加錯誤處理服務：

```swift
// DependencyContainer.swift

class DependencyContainer {
    // 單例模式
    static let shared = DependencyContainer()
    
    // 核心服務
    private let coreDataManager = CoreDataManager.shared
    let errorHandler = ErrorHandlingService()
    
    // Repositories
    lazy var babyRepository: BabyRepository = {
        return BabyRepositoryImpl(coreDataManager: coreDataManager)
    }()
    
    // 其他Repository...
    
    // UseCases
    lazy var getBabiesUseCase: GetBabiesUseCase = {
        return GetBabiesUseCase(babyRepository: babyRepository)
    }()
    
    // 其他UseCase...
    
    // ViewModels
    func makeBabySelectorViewModel() -> BabySelectorViewModel {
        return BabySelectorViewModel(
            getBabiesUseCase: getBabiesUseCase,
            errorHandler: errorHandler
        )
    }
    
    // 其他ViewModel工廠方法...
}
```

### 2.10 在應用入口點設置錯誤處理

在應用的入口點設置全局錯誤處理：

```swift
// BabyTrackerApp.swift

@main
struct BabyTrackerApp: App {
    // 使用依賴注入容器
    private let dependencyContainer = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencyContainer.errorHandler) // 注入錯誤處理服務
        }
    }
}
```

## 3. 具體修正實施

### 3.1 定義錯誤類型和服務

首先，創建錯誤類型和錯誤處理服務：

```swift
// AppError.swift
// 完整實現見2.1節

// ErrorHandlingService.swift
// 完整實現見2.2節
```

### 3.2 創建錯誤展示視圖和修飾器

接下來，創建錯誤展示視圖和修飾器：

```swift
// ErrorView.swift
// 完整實現見2.3節

// ErrorHandlingModifier.swift
// 完整實現見2.4節
```

### 3.3 修改Repository實現

修改所有Repository實現，使用統一的錯誤類型：

```swift
// BabyRepositoryImpl.swift
// 示例修改見2.5節

// SleepRepositoryImpl.swift
class SleepRepositoryImpl: SleepRepository {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    func getSleepRecords(babyId: UUID, completion: @escaping (Result<[SleepRecord], Error>) -> Void) {
        let context = coreDataManager.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<SleepRecordEntity> = SleepRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "babyId == %@", babyId as CVarArg)
        
        do {
            let sleepRecordEntities = try context.fetch(fetchRequest)
            let sleepRecords = sleepRecordEntities.map { $0.toDomain() }
            completion(.success(sleepRecords))
        } catch {
            // 轉換為應用錯誤類型
            let appError = AppError.dataError("無法獲取睡眠記錄：\(error.localizedDescription)")
            completion(.failure(appError))
        }
    }
    
    // 其他方法類似修改...
}

// EnvironmentFactorRepositoryImpl.swift
// ActivityRepositoryImpl.swift
// 其他Repository實現類似修改...
```

### 3.4 修改UseCase實現

確保所有UseCase正確傳遞錯誤：

```swift
// GetBabiesUseCase.swift
// 示例修改見2.6節

// GetSleepRecordsUseCase.swift
class GetSleepRecordsUseCase {
    private let sleepRepository: SleepRepository
    
    init(sleepRepository: SleepRepository) {
        self.sleepRepository = sleepRepository
    }
    
    func execute(babyId: UUID, completion: @escaping (Result<[SleepRecord], Error>) -> Void) {
        sleepRepository.getSleepRecords(babyId: babyId) { result in
            // 直接傳遞結果，保持錯誤類型
            completion(result)
        }
    }
}

// 其他UseCase實現類似修改...
```

### 3.5 修改ViewModel實現

修改所有ViewModel，使用錯誤處理服務：

```swift
// BabySelectorViewModel.swift
// 示例修改見2.7
(Content truncated due to size limit. Use line ranges to read in chunks)