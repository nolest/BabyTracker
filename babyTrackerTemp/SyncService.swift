import Foundation

/// 數據同步服務
class SyncService {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = SyncService()
    
    // MARK: - 屬性
    
    /// 網絡監視器
    private let networkMonitor: NetworkMonitor
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    /// 上次同步時間的鍵
    private let lastSyncTimeKey = Constants.UserDefaultsKeys.lastSyncTime
    
    /// 是否正在同步
    private(set) var isSyncing = false
    
    /// 同步狀態變更處理器
    var onSyncStatusChange: ((Bool) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    init(networkMonitor: NetworkMonitor = NetworkMonitor.shared, userSettings: UserSettings = UserSettings.shared) {
        self.networkMonitor = networkMonitor
        self.userSettings = userSettings
    }
    
    // MARK: - 公共方法
    
    /// 同步數據
    /// - Parameter completion: 完成回調
    func syncData(completion: @escaping (Result<Void, Error>) -> Void) {
        // 檢查網絡連接
        guard networkMonitor.isConnected else {
            let error = NSError(domain: Constants.ErrorDomains.network, code: 1, userInfo: [NSLocalizedDescriptionKey: "無網絡連接"])
            completion(.failure(error))
            return
        }
        
        // 檢查是否正在同步
        guard !isSyncing else {
            let error = NSError(domain: Constants.ErrorDomains.cloud, code: 2, userInfo: [NSLocalizedDescriptionKey: "同步已在進行中"])
            completion(.failure(error))
            return
        }
        
        // 更新同步狀態
        setSyncingStatus(true)
        
        // 執行同步
        performSync { result in
            // 更新同步狀態
            self.setSyncingStatus(false)
            
            // 回調
            completion(result)
        }
    }
    
    /// 獲取上次同步時間
    /// - Returns: 上次同步時間
    func getLastSyncTime() -> Date? {
        return UserDefaults.standard.object(forKey: lastSyncTimeKey) as? Date
    }
    
    // MARK: - 私有方法
    
    /// 執行同步
    /// - Parameter completion: 完成回調
    private func performSync(completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬同步過程
        DispatchQueue.global().async {
            // 模擬網絡延遲
            Thread.sleep(forTimeInterval: 2.0)
            
            // 更新上次同步時間
            let now = Date()
            UserDefaults.standard.set(now, forKey: self.lastSyncTimeKey)
            
            // 記錄日誌
            Logger.info("數據同步完成", category: .cloud)
            
            // 回調
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
    
    /// 設置同步狀態
    /// - Parameter syncing: 是否正在同步
    private func setSyncingStatus(_ syncing: Bool) {
        isSyncing = syncing
        
        // 通知狀態變更
        onSyncStatusChange?(syncing)
        
        // 記錄日誌
        if syncing {
            Logger.info("開始同步數據", category: .cloud)
        } else {
            Logger.info("結束同步數據", category: .cloud)
        }
    }
}
