// offline_mode_notification.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 離線模式提示實現

import Foundation
import UIKit
import Combine

// MARK: - 網絡狀態枚舉

/// 網絡狀態枚舉，表示當前網絡連接狀態
enum NetworkStatus {
    /// 未知狀態
    case unknown
    /// 離線狀態
    case offline
    /// 雲端分析已禁用
    case cloudDisabled
    /// 雲端分析可用
    case cloudAvailable
}

// MARK: - 網絡狀態監控擴展

extension NetworkMonitor {
    /// 獲取當前網絡狀態
    /// - Returns: 網絡狀態
    func getCurrentNetworkStatus() -> NetworkStatus {
        if !isConnected {
            return .offline
        } else if !canUseCloudAnalysis() {
            return .cloudDisabled
        } else {
            return .cloudAvailable
        }
    }
}

// MARK: - 網絡狀態視圖模型

/// 網絡狀態視圖模型，提供網絡狀態相關功能
class NetworkStatusViewModel {
    // MARK: - 依賴
    
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 發布者
    
    private let networkStatusSubject = CurrentValueSubject<NetworkStatus, Never>(.unknown)
    
    // MARK: - 公開的發布者
    
    /// 網絡狀態發布者
    var networkStatus: AnyPublisher<NetworkStatus, Never> {
        return networkStatusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 初始化
    
    /// 初始化網絡狀態視圖模型
    /// - Parameter networkMonitor: 網絡監控服務
    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
        
        // 監聽網絡狀態變化
        NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] _ in
                self?.updateNetworkStatus()
            }
            .store(in: &cancellables)
        
        // 初始化網絡狀態
        updateNetworkStatus()
    }
    
    // MARK: - 公開方法
    
    /// 更新網絡狀態
    func updateNetworkStatus() {
        let status = networkMonitor.getCurrentNetworkStatus()
        networkStatusSubject.send(status)
    }
    
    /// 檢查是否可以使用雲端分析
    /// - Returns: 是否可以使用雲端分析
    func canUseCloudAnalysis() -> Bool {
        return networkMonitor.canUseCloudAnalysis()
    }
    
    /// 獲取網絡狀態描述
    /// - Parameter status: 網絡狀態
    /// - Returns: 網絡狀態描述
    func getNetworkStatusDescription(_ status: NetworkStatus) -> String {
        switch status {
        case .unknown:
            return NSLocalizedString("未知網絡狀態", comment: "")
        case .offline:
            return NSLocalizedString("離線模式：部分高級功能不可用", comment: "")
        case .cloudDisabled:
            return NSLocalizedString("雲端分析已禁用：部分高級功能不可用", comment: "")
        case .cloudAvailable:
            return NSLocalizedString("雲端分析可用", comment: "")
        }
    }
    
    /// 獲取網絡狀態顏色
    /// - Parameter status: 網絡狀態
    /// - Returns: 網絡狀態顏色
    func getNetworkStatusColor(_ status: NetworkStatus) -> UIColor {
        switch status {
        case .unknown:
            return .gray
        case .offline:
            return .systemOrange
        case .cloudDisabled:
            return .systemYellow
        case .cloudAvailable:
            return .systemGreen
        }
    }
}

// MARK: - 離線模式橫幅視圖

/// 離線模式橫幅視圖，顯示當前網絡狀態
class OfflineBannerView: UIView {
    // MARK: - UI元素
    
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    
    // MARK: - 回調
    
    /// 重試按鈕點擊回調
    var onRetryTapped: (() -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化離線模式橫幅視圖
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        // 設置背景色
        backgroundColor = .systemYellow
        
        // 設置狀態標籤
        statusLabel.textColor = .black
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        // 設置重試按鈕
        retryButton.setTitle(NSLocalizedString("重試", comment: ""), for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(retryButton)
        
        // 設置約束
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            retryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            retryButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: retryButton.leadingAnchor, constant: -8)
        ])
    }
    
    // MARK: - 動作
    
    /// 重試按鈕點擊
    @objc private func retryButtonTapped() {
        onRetryTapped?()
    }
    
    // MARK: - 公開方法
    
    /// 更新狀態
    /// - Parameters:
    ///   - status: 網絡狀態
    ///   - description: 網絡狀態描述
    func updateStatus(status: NetworkStatus, description: String) {
        statusLabel.text = description
        backgroundColor = getBackgroundColor(for: status)
        isHidden = status == .cloudAvailable
    }
    
    /// 獲取背景顏色
    /// - Parameter status: 網絡狀態
    /// - Returns: 背景顏色
    private func getBackgroundColor(for status: NetworkStatus) -> UIColor {
        switch status {
        case .offline:
            return .systemOrange
        case .cloudDisabled:
            return .systemYellow
        default:
            return .systemGray
        }
    }
}

// MARK: - 視圖控制器擴展

extension UIViewController {
    /// 添加離線模式橫幅
    /// - Parameters:
    ///   - viewModel: 網絡狀態視圖模型
    ///   - topAnchor: 頂部錨點
    ///   - onRetry: 重試回調
    /// - Returns: 離線模式橫幅視圖和取消訂閱集合
    func addOfflineBanner(
        viewModel: NetworkStatusViewModel,
        topAnchor: NSLayoutYAxisAnchor,
        onRetry: @escaping () -> Void
    ) -> (banner: OfflineBannerView, cancellables: Set<AnyCancellable>) {
        // 創建離線模式橫幅
        let banner = OfflineBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.isHidden = true
        banner.onRetryTapped = onRetry
        view.addSubview(banner)
        
        // 設置約束
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: topAnchor),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            banner.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // 綁定視圖模型
        var cancellables = Set<AnyCancellable>()
        viewModel.networkStatus
            .receive(on: DispatchQueue.main)
            .sink { status in
                let description = viewModel.getNetworkStatusDescription(status)
                banner.updateStatus(status: status, description: description)
            }
            .store(in: &cancellables)
        
        return (banner, cancellables)
    }
}

// MARK: - 視圖模型擴展

extension SleepAnalysisViewModel {
    /// 檢查網絡狀態
    /// - Returns: 是否在離線模式
    func checkNetworkStatus() -> Bool {
        let networkStatus = networkMonitor.getCurrentNetworkStatus()
        
        // 如果離線，發送錯誤信息
        if networkStatus == .offline {
            let offlineMessage = NSLocalizedString(
                "您目前處於離線模式。將使用本地分析，某些高級功能可能不可用。",
                comment: ""
            )
            errorMessageSubject.send(offlineMessage)
            return true
        }
        
        // 如果雲端分析已禁用，發送提示信息
        if networkStatus == .cloudDisabled {
            let disabledMessage = NSLocalizedString(
                "雲端分析已禁用。將使用本地分析，某些高級功能可能不可用。",
                comment: ""
            )
            errorMessageSubject.send(disabledMessage)
            return true
        }
        
        return false
    }
}

// MARK: - 睡眠分析視圖控制器示例

/// 睡眠分析視圖控制器，展示離線模式提示的使用
class SleepAnalysisViewController: UIViewController {
    // MARK: - 依賴
    
    private let viewModel: SleepAnalysisViewModel
    private let networkStatusViewModel: NetworkStatusViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI元素
    
    private var offlineBanner: OfflineBannerView!
    
    // MARK: - 初始化
    
    /// 初始化睡眠分析視圖控制器
    /// - Parameters:
    ///   - viewModel: 睡眠分析視圖模型
    ///   - networkStatusViewModel: 網絡狀態視圖模型
    init(viewModel: SleepAnalysisViewModel, networkStatusViewModel: NetworkStatusViewModel) {
        self.viewModel = viewModel
        self.networkStatusViewModel = networkStatusViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupOfflineBanner()
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        // 設置視圖控制器UI
    }
    
    /// 設置離線模式橫幅
    private func setupOfflineBanner() {
        // 添加離線模式橫幅
        let result = addOfflineBanner(
            viewModel: networkStatusViewModel,
            topAnchor: view.safeAreaLayoutGuide.topAnchor,
            onRetry: { [weak self] in
                self?.retryConnection()
            }
        )
        
        offlineBanner = result.banner
        cancellables.formUnion(result.cancellables)
    }
    
    /// 重試連接
    private func retryConnection() {
        // 更新網絡狀態
        networkStatusViewModel.updateNetworkStatus()
        
        // 如果已連接網絡，重新分析
        if networkStatusViewModel.canUseCloudAnalysis() {
            performAnalysis()
        }
    }
    
    /// 執行分析
    private func performAnalysis() {
        // 檢查網絡狀態
        if viewModel.checkNetworkStatus() {
            // 如果離線或雲端分析已禁用，顯示提示但仍然繼續分析
            // 視圖模型會自動降級到本地分析
        }
        
        // 執行分析
        let babyId = "current_baby_id" // 從某處獲取
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
        viewModel.analyzeSleepPattern(babyId: babyId, dateRange: startDate...endDate)
    }
}

// MARK: - 工廠方法

/// 創建睡眠分析視圖控制器
/// - Returns: 睡眠分析視圖控制器
func createSleepAnalysisViewController() -> SleepAnalysisViewController {
    let serviceLocator = ServiceLocator.shared
    
    // 創建視圖模型
    let aiEngine = serviceLocator.aiEngine
    let networkMonitor = serviceLocator.networkMonitor
    let errorHandler = serviceLocator.errorHandler()
    
    let viewModel = SleepAnalysisViewModel(
        aiEngine: aiEngine,
        errorHandler: errorHandler,
        networkMonitor: networkMonitor
    )
    
    let networkStatusViewModel = NetworkStatusViewModel(networkMonitor: networkMonitor)
    
    // 創建視圖控制器
    let viewController = SleepAnalysisViewController(
        viewModel: viewModel,
        networkStatusViewModel: networkStatusViewModel
    )
    
    // 更新錯誤處理器的視圖控制器引用
    if let appErrorHandler = errorHandler as? AppErrorHandler {
        appErrorHandler.viewController = viewController
    }
    
    return viewController
}

// MARK: - 睡眠分析視圖模型擴展

extension SleepAnalysisViewModel {
    /// 初始化睡眠分析視圖模型
    /// - Parameters:
    ///   - aiEngine: AI引擎
    ///   - errorHandler: 錯誤處理器
    ///   - networkMonitor: 網絡監控服務
    convenience init(aiEngine: AIEngine, errorHandler: ErrorHandler, networkMonitor: NetworkMonitor) {
        self.init(aiEngine: aiEngine, errorHandler: errorHandler)
        self.networkMonitor = networkMonitor
    }
    
    // MARK: - 屬性
    
    /// 網絡監控服務
    private(set) var networkMonitor: NetworkMonitor!
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    override func analyzeSleepPattern(babyId: String, dateRange: ClosedRange<Date>) {
        isLoadingSubject.send(true)
        errorMessageSubject.send(nil)
        
        // 檢查網絡狀態
        let networkStatus = networkMonitor.getCurrentNetworkStatus()
        
        // 如果離線，發送提示信息
        if networkStatus == .offline {
            let offlineMessage = NSLocalizedString(
                "您目前處於離線模式。將使用本地分析，某些高級功能可能不可用。",
                comment: ""
            )
            errorMessageSubject.send(offlineMessage)
        }
        
        // 如果雲端分析已禁用，發送提示信息
        if networkStatus == .cloudDisabled {
            let disabledMessage = NSLocalizedString(
                "雲端分析已禁用。將使用本地分析，某些高級功能可能不可用。",
                comment: ""
            )
            errorMessageSubject.send(disabledMessage)
        }
        
        // 繼續分析流程
        super.analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
    }
}
