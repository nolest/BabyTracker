// NetworkMonitor.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：Deepseek API整合
// 網絡狀態監控

import Foundation
import Network

/// 監控網絡連接狀態，提供當前網絡類型和可用性信息
class NetworkMonitor {
    // MARK: - 單例模式
    static let shared = NetworkMonitor()
    
    // MARK: - 網絡類型枚舉
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    // MARK: - 屬性
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private(set) var isConnected = false
    private(set) var connectionType: ConnectionType = .unknown
    
    // MARK: - 初始化
    private init() {
        startMonitoring()
    }
    
    // MARK: - 公開方法
    
    /// 開始監控網絡狀態
    func startMonitoring() {
        monitor.start(queue: queue)
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // 更新連接狀態
            self.isConnected = path.status == .satisfied
            
            // 更新連接類型
            self.connectionType = self.getConnectionType(path)
            
            // 發送通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil
                )
            }
        }
    }
    
    /// 停止監控網絡狀態
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// 檢查是否可以使用雲端分析
    /// - Returns: 是否可以使用雲端分析
    func canUseCloudAnalysis() -> Bool {
        let settings = UserSettings.shared
        
        // 如果用戶未啟用雲端分析，則不可用
        guard settings.isCloudAnalysisEnabled else {
            return false
        }
        
        // 如果沒有API Key，則不可用
        guard settings.deepseekAPIKey != nil else {
            return false
        }
        
        // 如果沒有網絡連接，則不可用
        guard isConnected else {
            return false
        }
        
        // 如果設置僅在WiFi下使用雲端分析，則檢查當前是否為WiFi
        if settings.useCloudAnalysisOnlyOnWiFi {
            return connectionType == .wifi
        }
        
        // 其他情況下可用
        return true
    }
    
    // MARK: - 私有方法
    
    /// 獲取當前網絡連接類型
    /// - Parameter path: 網絡路徑
    /// - Returns: 連接類型
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

// MARK: - 通知名稱擴展
extension Notification.Name {
    /// 網絡狀態變更通知
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
