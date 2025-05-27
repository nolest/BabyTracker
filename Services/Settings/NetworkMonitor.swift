import Foundation
import Network

/// 網絡監視器
class NetworkMonitor {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = NetworkMonitor()
    
    // MARK: - 屬性
    
    /// 網絡路徑監視器
    private let monitor = NWPathMonitor()
    
    /// 操作隊列
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// 當前網絡狀態
    private(set) var isConnected = false
    
    /// 當前網絡類型
    private(set) var connectionType: ConnectionType = .unknown
    
    /// 網絡狀態變更處理器
    var onStatusChange: ((Bool, ConnectionType) -> Void)?
    
    // MARK: - 網絡連接類型
    
    /// 網絡連接類型
    enum ConnectionType {
        /// 未知
        case unknown
        
        /// WiFi
        case wifi
        
        /// 蜂窩網絡
        case cellular
        
        /// 有線
        case wired
        
        /// 其他
        case other
    }
    
    // MARK: - 初始化
    
    /// 初始化方法
    init() {
        startMonitoring()
    }
    
    // MARK: - 公共方法
    
    /// 開始監視網絡狀態
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // 更新連接狀態
            self.isConnected = path.status == .satisfied
            
            // 更新連接類型
            self.connectionType = self.getConnectionType(from: path)
            
            // 通知狀態變更
            self.onStatusChange?(self.isConnected, self.connectionType)
            
            // 發送通知
            NotificationCenter.default.post(
                name: Constants.NotificationNames.networkStatusChanged,
                object: nil,
                userInfo: [
                    "isConnected": self.isConnected,
                    "connectionType": self.connectionType
                ]
            )
            
            // 記錄日誌
            Logger.info("網絡狀態變更: 已連接=\(self.isConnected), 類型=\(self.connectionType)", category: .network)
        }
        
        // 在指定隊列上啟動監視器
        monitor.start(queue: queue)
    }
    
    /// 停止監視網絡狀態
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// 檢查是否可以使用雲端服務
    /// - Returns: 是否可以使用雲端服務
    func canUseCloudServices() -> Bool {
        // 檢查網絡連接
        guard isConnected else {
            return false
        }
        
        // 檢查用戶設置
        let userSettings = DependencyContainer.shared.resolve(UserSettings.self)
        let isCloudAIEnabled = userSettings?.isCloudAIEnabled ?? false
        
        return isCloudAIEnabled
    }
    
    // MARK: - 私有方法
    
    /// 獲取連接類型
    /// - Parameter path: 網絡路徑
    /// - Returns: 連接類型
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else {
            return path.status == .satisfied ? .other : .unknown
        }
    }
}
