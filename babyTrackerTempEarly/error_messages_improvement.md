# 寶寶生活記錄專業版（Baby Tracker）- 錯誤消息改進

## 1. 問題描述

在整合驗證過程中，發現某些自定義錯誤消息不夠用戶友好，可能導致以下問題：

1. 用戶難以理解錯誤原因，增加使用困難
2. 錯誤消息過於技術性，對普通用戶不友好
3. 缺少明確的解決方案建議，用戶不知如何處理錯誤
4. 錯誤消息格式不一致，影響用戶體驗
5. 缺少錯誤日誌記錄機制，難以追蹤和解決問題

## 2. 修正方案

### 2.1 改進錯誤類型定義

首先，擴展 AppError 類型，提供更友好的錯誤消息：

```swift
// AppError.swift

enum AppError: Error {
    case networkError(String)
    case databaseError(String)
    case entityNotFound(String)
    case validationError(String)
    case authenticationError(String)
    case permissionError(String)
    case serverError(String)
    case unknownError(String)
    
    // 原始的用戶消息
    var userMessage: String {
        switch self {
        case .networkError(let message):
            return "網絡錯誤：\(message)"
        case .databaseError(let message):
            return "數據庫錯誤：\(message)"
        case .entityNotFound(let message):
            return "找不到數據：\(message)"
        case .validationError(let message):
            return "驗證錯誤：\(message)"
        case .authenticationError(let message):
            return "認證錯誤：\(message)"
        case .permissionError(let message):
            return "權限錯誤：\(message)"
        case .serverError(let message):
            return "服務器錯誤：\(message)"
        case .unknownError(let message):
            return "未知錯誤：\(message)"
        }
    }
    
    // 改進的用戶友好消息
    var improvedUserMessage: String {
        switch self {
        case .networkError(let message):
            return "網絡連接問題，請檢查您的網絡連接並重試。如果問題持續存在，請稍後再試。"
        case .databaseError(let message):
            return "數據存儲問題，您的數據可能未能正確保存。請重試，如果問題持續存在，請重新啟動應用。"
        case .entityNotFound(let message):
            return "找不到所需數據，可能已被刪除或尚未創建。"
        case .validationError(let message):
            return "輸入數據有誤：\(message)。請檢查並修正後重試。"
        case .authenticationError(let message):
            return "登錄憑證已過期或無效。請重新登錄後再試。"
        case .permissionError(let message):
            return "您沒有執行此操作的權限。請確認您的帳戶權限或聯繫管理員。"
        case .serverError(let message):
            return "服務器暫時無法響應。請稍後再試，我們正在努力解決此問題。"
        case .unknownError(let message):
            return "發生未知問題。請重試，如果問題持續存在，請重新啟動應用或聯繫客服。"
        }
    }
    
    // 錯誤解決建議
    var suggestion: String? {
        switch self {
        case .networkError:
            return "• 檢查您的網絡連接\n• 確認Wi-Fi或移動數據已開啟\n• 嘗試切換網絡連接方式\n• 重新啟動應用"
        case .databaseError:
            return "• 確保設備有足夠存儲空間\n• 重新啟動應用\n• 如果問題持續存在，請嘗試重新安裝應用（注意：這可能會導致數據丟失）"
        case .entityNotFound:
            return "• 檢查您是否已創建相關數據\n• 刷新頁面\n• 確認您正在查看正確的寶寶資料"
        case .validationError:
            return "• 檢查輸入的數據格式是否正確\n• 確保必填字段已填寫\n• 檢查數值是否在允許範圍內"
        case .authenticationError:
            return "• 重新登錄\n• 確認您的帳戶信息\n• 如果忘記密碼，請使用「忘記密碼」功能"
        case .permissionError:
            return "• 確認您的帳戶權限\n• 聯繫寶寶資料的管理員\n• 檢查您的家庭共享設置"
        case .serverError:
            return "• 稍後再試\n• 檢查應用是否有更新\n• 確認您的網絡連接"
        case .unknownError:
            return "• 重新啟動應用\n• 檢查應用是否有更新\n• 聯繫客服獲取幫助"
        }
    }
    
    // 錯誤嚴重程度
    var severity: ErrorSeverity {
        switch self {
        case .networkError, .serverError:
            return .warning
        case .databaseError, .authenticationError:
            return .moderate
        case .entityNotFound, .validationError, .permissionError:
            return .minor
        case .unknownError:
            return .critical
        }
    }
}

// 錯誤嚴重程度
enum ErrorSeverity {
    case minor      // 輕微錯誤，不影響主要功能
    case warning    // 警告，可能影響部分功能
    case moderate   // 中度錯誤，影響某些重要功能
    case critical   // 嚴重錯誤，可能導致應用崩潰或數據丟失
    
    var color: Color {
        switch self {
        case .minor:
            return .blue
        case .warning:
            return .orange
        case .moderate:
            return .yellow
        case .critical:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .minor:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .moderate:
            return "exclamationmark.circle"
        case .critical:
            return "xmark.octagon"
        }
    }
}

// 擴展 Error 協議，將任何錯誤轉換為 AppError
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

### 2.2 改進錯誤處理服務

接下來，改進 ErrorHandlingService 以使用新的錯誤消息格式：

```swift
// ErrorHandlingService.swift

class ErrorHandlingService: ObservableObject {
    @Published var currentError: DisplayableError?
    @Published var isShowingError: Bool = false
    
    private var errorLogger: ErrorLogger = ErrorLogger()
    
    func handle(_ error: Error) {
        let appError = error.asAppError
        
        // 記錄錯誤
        errorLogger.log(appError)
        
        // 創建可顯示的錯誤
        let displayableError = DisplayableError(
            title: errorTitleForSeverity(appError.severity),
            message: appError.improvedUserMessage,
            suggestion: appError.suggestion,
            severity: appError.severity
        )
        
        // 在主線程更新 UI
        DispatchQueue.main.async { [weak self] in
            self?.currentError = displayableError
            self?.isShowingError = true
        }
    }
    
    func handleResult<T>(_ result: Result<T, Error>, onSuccess: (T) -> Void) {
        switch result {
        case .success(let value):
            onSuccess(value)
        case .failure(let error):
            handle(error)
        }
    }
    
    func dismissError() {
        isShowingError = false
        currentError = nil
    }
    
    private func errorTitleForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .minor:
            return "提示"
        case .warning:
            return "警告"
        case .moderate:
            return "錯誤"
        case .critical:
            return "嚴重錯誤"
        }
    }
}

// 可顯示的錯誤結構
struct DisplayableError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let suggestion: String?
    let severity: ErrorSeverity
    let timestamp = Date()
}

// 錯誤日誌記錄器
class ErrorLogger {
    private let maxLogEntries = 100
    private var logEntries: [ErrorLogEntry] = []
    
    func log(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        let appError = error.asAppError
        let entry = ErrorLogEntry(
            error: appError,
            file: file,
            line: line,
            function: function,
            timestamp: Date()
        )
        
        // 添加日誌條目
        logEntries.append(entry)
        
        // 限制日誌條目數量
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst()
        }
        
        // 打印到控制台
        print("ERROR [\(entry.file):\(entry.line) \(entry.function)] - \(appError.improvedUserMessage)")
        
        // 在實際應用中，可以將錯誤發送到日誌服務
        // sendToLogService(entry)
    }
    
    func getRecentLogs(count: Int = 10) -> [ErrorLogEntry] {
        let endIndex = min(count, logEntries.count)
        return Array(logEntries.suffix(endIndex))
    }
    
    func clearLogs() {
        logEntries.removeAll()
    }
}

// 錯誤日誌條目
struct ErrorLogEntry {
    let id = UUID()
    let error: AppError
    let file: String
    let line: Int
    let function: String
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    var shortFileName: String {
        let components = file.components(separatedBy: "/")
        return components.last ?? file
    }
}
```

### 2.3 創建錯誤顯示視圖

創建一個統一的錯誤顯示視圖：

```swift
// ErrorView.swift

struct ErrorView: View {
    let error: DisplayableError
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: error.severity.icon)
                    .foregroundColor(error.severity.color)
                    .font(.title2)
                
                Text(error.title)
                    .font(.headline)
                    .foregroundColor(error.severity.color)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // 錯誤消息
            Text(error.message)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            // 建議（如果有）
            if let suggestion = error.suggestion {
                VStack(alignment: .leading, spacing: 8) {
                    Text("建議解決方法：")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(suggestion)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            
            // 按鈕
            HStack {
                Spacer()
                
                Button(action: onDismiss) {
                    Text("關閉")
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
    }
}

// 錯誤顯示修飾器
struct ErrorViewModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandlingService
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if errorHandler.isShowingError, let error = errorHandler.currentError {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                // 點擊背景不關閉嚴重錯誤
                                if error.severity != .critical {
                                    errorHandler.dismissError()
                                }
                            }
                        
                        ErrorView(error: error) {
                            errorHandler.dismissError()
                        }
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(100)
                    }
                }
                .animation(.easeInOut, value: errorHandler.isShowingError)
            )
    }
}

// 擴展 View 以方便使用錯誤處理修飾器
extension View {
    func handleErrors(with errorHandler: ErrorHandlingService) -> some View {
        self.modifier(ErrorViewModifier(errorHandler: errorHandler))
    }
}
```

### 2.4 創建輕量級錯誤提示

對於不需要中斷用戶操作的輕微錯誤，創建一個輕量級的錯誤提示：

```swift
// ErrorToastView.swift

struct ErrorToastView: View {
    let error: DisplayableError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.severity.icon)
                .foregroundColor(error.severity.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(error.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// 輕量級錯誤提示修飾器
struct ErrorToastModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandlingService
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()
                    
                    if errorHandler.isShowingError, let error = errorHandler.currentError, error.severity == .minor {
                        ErrorToastView(error: error) {
                            errorHandler.dismissError()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom)
                    }
                }
                .animation(.easeInOut, value: errorHandler.isShowingError)
                .edgesIgnoringSafeArea(.bottom)
            )
    }
}

// 擴展 View 以方便使用輕量級錯誤提示修飾器
extension View {
    func handleMinorErrors(with errorHandler: ErrorHandlingService) -> some View {
        self.modifier(ErrorToastModifier(errorHandler: errorHandler))
    }
}
```

### 2.5 更新錯誤處理策略

更新 ErrorHandlingService 以根據錯誤嚴重程度選擇不同的顯示方式：

```swift
// ErrorHandlingService.swift (更新)

class ErrorHandlingService: ObservableObject {
    @Published var currentError: DisplayableError?
    @Published var isShowingError: Bool = false
    @Published var isShowingToast: Bool = false
    @Published var toastError: DisplayableError?
    
    private var errorLogger: ErrorLogger = ErrorLogger()
    private var errorDismissTimer: Timer?
    
    func handle(_ error: Error) {
        let appError = error.asAppError
        
        // 記錄錯誤
        errorLogger.log(appError)
        
        // 創建可顯示的錯誤
        let displayableError = DisplayableError(
            title: errorTitleForSeverity(appError.severity),
            message: appError.improvedUserMessage,
            suggestion: appError.suggestion,
            severity: appError.severity
        )
        
        // 在主線程更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 根據錯誤嚴重程度選擇顯示方式
            switch appError.severity {
            case .minor:
                self.showToast(displayableError)
            case .warning, .moderate, .critical:
                self.showModal(displayableError)
            }
        }
    }
    
    private func showModal(_ error: DisplayableError) {
        // 取消任何正在顯示的輕量級錯誤
        isShowingToast = false
        toastError = nil
        errorDismissTimer?.invalidate()
        
        // 顯示模態錯誤
        currentError = error
        isShowingError = true
    }
    
    private func showToast(_ error: DisplayableError) {
        // 如果已經在顯示更嚴重的錯誤，不要顯示輕量級錯誤
        guard !isShowingError else { return }
        
        // 顯示輕量級錯誤
        toastError = error
        isShowingToast = true
        
        // 設置自動消失計時器
        errorDismissTimer?.invalidate()
        errorDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.dismissToast()
            }
        }
    }
    
    func dismissError() {
        isShowingError = false
        currentError = nil
    }
    
    func dismissToast() {
        isShowingToast = false
        toastError = nil
        errorDismissTimer?.invalidate()
    }
    
    // 其他方法...
}
```

### 2.6 更新視圖以使用新的錯誤處理

更新所有視圖以使用新的錯誤處理機制：

```swift
// ContentView.swift

struct ContentView: View {
    @EnvironmentObject var errorHandler: ErrorHandlingService
    
    var body: some View {
        TabView {
            // 主頁標籤
            HomeView()
                .tabItem
(Content truncated due to size limit. Use line ranges to read in chunks)