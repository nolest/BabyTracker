// error_handling_improvement.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 錯誤處理完善實現

import Foundation
import UIKit
import Combine

// MARK: - 錯誤處理器協議

/// 錯誤處理器協議，定義錯誤處理的標準接口
protocol ErrorHandler {
    /// 處理錯誤
    /// - Parameter error: 錯誤對象
    func handle(_ error: Error)
    
    /// 獲取錯誤信息
    /// - Parameter error: 錯誤對象
    /// - Returns: 用戶友好的錯誤信息
    func getErrorMessage(for error: Error) -> String
}

// MARK: - 應用錯誤處理器

/// 應用錯誤處理器，實現統一的錯誤處理邏輯
class AppErrorHandler: ErrorHandler {
    // MARK: - 屬性
    
    /// 關聯的視圖控制器，用於顯示錯誤對話框
    weak var viewController: UIViewController?
    
    // MARK: - 初始化
    
    /// 初始化應用錯誤處理器
    /// - Parameter viewController: 關聯的視圖控制器
    init(viewController: UIViewController? = nil) {
        self.viewController = viewController
    }
    
    // MARK: - ErrorHandler 協議實現
    
    /// 處理錯誤
    /// - Parameter error: 錯誤對象
    func handle(_ error: Error) {
        let message = getErrorMessage(for: error)
        
        // 記錄錯誤
        logError(error, message: message)
        
        // 顯示錯誤給用戶
        showErrorToUser(message: message)
    }
    
    /// 獲取錯誤信息
    /// - Parameter error: 錯誤對象
    /// - Returns: 用戶友好的錯誤信息
    func getErrorMessage(for error: Error) -> String {
        // 根據錯誤類型返回用戶友好的錯誤信息
        if let cloudError = error as? CloudError {
            return getCloudErrorMessage(cloudError)
        } else if let aiError = error as? AIError {
            return getAIErrorMessage(aiError)
        } else if let networkError = error as? URLError {
            return getNetworkErrorMessage(networkError)
        } else if let decodingError = error as? DecodingError {
            return getDecodingErrorMessage(decodingError)
        } else if let apiError = error as? DeepseekAPIClient.APIError {
            return getAPIErrorMessage(apiError)
        } else {
            return error.localizedDescription
        }
    }
    
    // MARK: - 私有方法
    
    /// 記錄錯誤
    /// - Parameters:
    ///   - error: 錯誤對象
    ///   - message: 錯誤信息
    private func logError(_ error: Error, message: String) {
        // 在實際應用中，這裡應該使用日誌系統記錄錯誤
        print("Error: \(error), Message: \(message)")
    }
    
    /// 顯示錯誤給用戶
    /// - Parameter message: 錯誤信息
    private func showErrorToUser(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let viewController = self.viewController {
                // 如果有視圖控制器，顯示錯誤對話框
                self.showErrorAlert(on: viewController, message: message)
            } else {
                // 如果沒有視圖控制器，使用通知
                NotificationCenter.default.post(
                    name: .errorOccurred,
                    object: nil,
                    userInfo: ["message": message]
                )
            }
        }
    }
    
    /// 顯示錯誤對話框
    /// - Parameters:
    ///   - viewController: 視圖控制器
    ///   - message: 錯誤信息
    private func showErrorAlert(on viewController: UIViewController, message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("錯誤", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("確定", comment: ""),
            style: .default
        ))
        
        viewController.present(alert, animated: true)
    }
    
    /// 獲取雲端錯誤信息
    /// - Parameter error: 雲端錯誤
    /// - Returns: 用戶友好的錯誤信息
    private func getCloudErrorMessage(_ error: CloudError) -> String {
        switch error {
        case .cloudAnalysisDisabled:
            return NSLocalizedString("雲端分析已禁用。請在設置中啟用雲端分析。", comment: "")
        case .insufficientData:
            return NSLocalizedString("數據不足，無法進行分析。請添加更多記錄後重試。", comment: "")
        case .invalidAPIKey:
            return NSLocalizedString("API密鑰無效。請聯繫客服獲取支持。", comment: "")
        case .networkError:
            return NSLocalizedString("網絡錯誤。請檢查您的網絡連接後重試。", comment: "")
        case .serverError:
            return NSLocalizedString("服務器錯誤。請稍後重試。", comment: "")
        case .rateLimitExceeded:
            return NSLocalizedString("已達到API使用限制。請稍後重試。", comment: "")
        case .timeout:
            return NSLocalizedString("請求超時。請檢查您的網絡連接後重試。", comment: "")
        case .unknownError:
            return NSLocalizedString("發生未知錯誤。請稍後重試。", comment: "")
        }
    }
    
    /// 獲取AI錯誤信息
    /// - Parameter error: AI錯誤
    /// - Returns: 用戶友好的錯誤信息
    private func getAIErrorMessage(_ error: AIError) -> String {
        switch error {
        case .engineNotAvailable:
            return NSLocalizedString("AI引擎不可用。請稍後重試。", comment: "")
        case .insufficientData:
            return NSLocalizedString("數據不足，無法進行分析。請添加更多記錄後重試。", comment: "")
        case .analysisFailed:
            return NSLocalizedString("分析失敗。請稍後重試。", comment: "")
        case .predictionFailed:
            return NSLocalizedString("預測失敗。請稍後重試。", comment: "")
        }
    }
    
    /// 獲取網絡錯誤信息
    /// - Parameter error: 網絡錯誤
    /// - Returns: 用戶友好的錯誤信息
    private func getNetworkErrorMessage(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return NSLocalizedString("無法連接到網絡。請檢查您的網絡連接後重試。", comment: "")
        case .timedOut:
            return NSLocalizedString("網絡請求超時。請檢查您的網絡連接後重試。", comment: "")
        case .cannotFindHost:
            return NSLocalizedString("無法找到服務器。請稍後重試。", comment: "")
        case .cannotConnectToHost:
            return NSLocalizedString("無法連接到服務器。請稍後重試。", comment: "")
        default:
            return NSLocalizedString("網絡錯誤：\(error.localizedDescription)。請稍後重試。", comment: "")
        }
    }
    
    /// 獲取解碼錯誤信息
    /// - Parameter error: 解碼錯誤
    /// - Returns: 用戶友好的錯誤信息
    private func getDecodingErrorMessage(_ error: DecodingError) -> String {
        return NSLocalizedString("數據格式錯誤。請更新應用或聯繫客服獲取支持。", comment: "")
    }
    
    /// 獲取API錯誤信息
    /// - Parameter error: API錯誤
    /// - Returns: 用戶友好的錯誤信息
    private func getAPIErrorMessage(_ error: DeepseekAPIClient.APIError) -> String {
        switch error {
        case .invalidURL:
            return NSLocalizedString("無效的URL。請聯繫客服獲取支持。", comment: "")
        case .invalidAPIKey:
            return NSLocalizedString("API密鑰無效。請聯繫客服獲取支持。", comment: "")
        case .networkError:
            return NSLocalizedString("網絡錯誤。請檢查您的網絡連接後重試。", comment: "")
        case .serverError(let code, _):
            return NSLocalizedString("服務器錯誤（代碼：\(code)）。請稍後重試。", comment: "")
        case .decodingError:
            return NSLocalizedString("數據格式錯誤。請更新應用或聯繫客服獲取支持。", comment: "")
        case .noData:
            return NSLocalizedString("未收到數據。請稍後重試。", comment: "")
        case .rateLimitExceeded:
            return NSLocalizedString("已達到API使用限制。請稍後重試。", comment: "")
        case .timeout:
            return NSLocalizedString("請求超時。請檢查您的網絡連接後重試。", comment: "")
        case .unknown:
            return NSLocalizedString("發生未知錯誤。請稍後重試。", comment: "")
        }
    }
}

// MARK: - 通知名稱擴展

extension Notification.Name {
    /// 錯誤發生通知
    static let errorOccurred = Notification.Name("errorOccurred")
}

// MARK: - 視圖模型錯誤處理擴展

/// 視圖模型錯誤處理擴展，提供統一的錯誤處理方法
extension SleepAnalysisViewModel {
    /// 處理錯誤
    /// - Parameter error: 錯誤對象
    func handleError(_ error: Error) {
        errorHandler.handle(error)
        errorMessageSubject.send(errorHandler.getErrorMessage(for: error))
    }
}

// MARK: - 視圖控制器錯誤處理擴展

/// 視圖控制器錯誤處理擴展，提供統一的錯誤處理方法
extension UIViewController {
    /// 設置錯誤通知觀察者
    func setupErrorNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleErrorNotification(_:)),
            name: .errorOccurred,
            object: nil
        )
    }
    
    /// 處理錯誤通知
    /// - Parameter notification: 通知對象
    @objc private func handleErrorNotification(_ notification: Notification) {
        guard let message = notification.userInfo?["message"] as? String else { return }
        
        // 顯示錯誤對話框
        let alert = UIAlertController(
            title: NSLocalizedString("錯誤", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("確定", comment: ""),
            style: .default
        ))
        
        present(alert, animated: true)
    }
}

// MARK: - 錯誤處理示例

/// 睡眠分析視圖模型，展示統一錯誤處理的使用
class SleepAnalysisViewModel {
    // MARK: - 依賴
    
    private let aiEngine: AIEngine
    let errorHandler: ErrorHandler
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 發布者
    
    private let analysisResultSubject = CurrentValueSubject<SleepPatternResult?, Never>(nil)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    let errorMessageSubject = CurrentValueSubject<String?, Never>(nil)
    
    // MARK: - 公開的發布者
    
    /// 分析結果發布者
    var analysisResult: AnyPublisher<SleepPatternResult?, Never> {
        return analysisResultSubject.eraseToAnyPublisher()
    }
    
    /// 加載狀態發布者
    var isLoading: AnyPublisher<Bool, Never> {
        return isLoadingSubject.eraseToAnyPublisher()
    }
    
    /// 錯誤信息發布者
    var errorMessage: AnyPublisher<String?, Never> {
        return errorMessageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 初始化
    
    /// 初始化睡眠分析視圖模型
    /// - Parameters:
    ///   - aiEngine: AI引擎
    ///   - errorHandler: 錯誤處理器
    init(aiEngine: AIEngine, errorHandler: ErrorHandler) {
        self.aiEngine = aiEngine
        self.errorHandler = errorHandler
    }
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    func analyzeSleepPattern(babyId: String, dateRange: ClosedRange<Date>) {
        isLoadingSubject.send(true)
        errorMessageSubject.send(nil)
        
        aiEngine.analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoadingSubject.send(false)
                    
                    if case .failure(let error) = completion {
                        self.handleError(error)
                    }
                },
                receiveValue: { [weak self] result in
                    self?.analysisResultSubject.send(result)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - 錯誤處理示例視圖控制器

/// 睡眠分析視圖控制器，展示統一錯誤處理的使用
class SleepAnalysisViewController: UIViewController {
    // MARK: - 屬性
    
    private let viewModel: SleepAnalysisViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI元素
    
    private let errorLabel = UILabel()
    
    // MARK: - 初始化
    
    /// 初始化睡眠分析視圖控制器
    /// - Parameter viewModel: 睡眠分析視圖模型
    init(viewModel: SleepAnalysisViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindViewModel()
        setupErrorNotificationObserver()
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        // 設置錯誤標籤
        errorLabel.textColor = .red
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        
        // 設置約束
        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    /// 綁定視圖模型
    private func bindViewModel() {
        // 綁定錯誤信息
        viewModel.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    self?.errorLabel.text = errorMessage
                    self?.errorLabel.isHidden = false
                } else {
                    self?.errorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
}
