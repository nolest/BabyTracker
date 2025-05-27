import Foundation

/// 數據遷移服務
class DataMigrationService {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = DataMigrationService()
    
    // MARK: - 屬性
    
    /// 當前數據庫版本
    private let currentDatabaseVersion = 1
    
    /// 數據庫版本鍵
    private let databaseVersionKey = "databaseVersion"
    
    /// 是否正在遷移
    private(set) var isMigrating = false
    
    /// 遷移狀態變更處理器
    var onMigrationStatusChange: ((Bool) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    init() {}
    
    // MARK: - 公共方法
    
    /// 檢查並執行遷移
    /// - Parameter completion: 完成回調
    func checkAndPerformMigration(completion: @escaping (Result<Void, Error>) -> Void) {
        // 獲取存儲的數據庫版本
        let storedVersion = UserDefaults.standard.integer(forKey: databaseVersionKey)
        
        // 檢查是否需要遷移
        guard storedVersion < currentDatabaseVersion else {
            // 不需要遷移
            completion(.success(()))
            return
        }
        
        // 檢查是否正在遷移
        guard !isMigrating else {
            let error = NSError(domain: "DataMigrationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "遷移已在進行中"])
            completion(.failure(error))
            return
        }
        
        // 更新遷移狀態
        setMigrationStatus(true)
        
        // 執行遷移
        performMigration(from: storedVersion, to: currentDatabaseVersion) { result in
            // 更新遷移狀態
            self.setMigrationStatus(false)
            
            // 回調
            completion(result)
        }
    }
    
    // MARK: - 私有方法
    
    /// 執行遷移
    /// - Parameters:
    ///   - fromVersion: 起始版本
    ///   - toVersion: 目標版本
    ///   - completion: 完成回調
    private func performMigration(from fromVersion: Int, to toVersion: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        // 記錄日誌
        Logger.info("開始數據遷移: 從版本 \(fromVersion) 到版本 \(toVersion)", category: .database)
        
        // 模擬遷移過程
        DispatchQueue.global().async {
            // 模擬延遲
            Thread.sleep(forTimeInterval: 2.0)
            
            // 根據版本執行不同的遷移
            for version in (fromVersion + 1)...toVersion {
                switch version {
                case 1:
                    // 遷移到版本1的邏輯
                    Logger.info("執行版本1遷移", category: .database)
                    // 模擬延遲
                    Thread.sleep(forTimeInterval: 0.5)
                    break
                    
                case 2:
                    // 遷移到版本2的邏輯
                    Logger.info("執行版本2遷移", category: .database)
                    // 模擬延遲
                    Thread.sleep(forTimeInterval: 0.5)
                    break
                    
                default:
                    // 未知版本
                    Logger.warning("未知的數據庫版本: \(version)", category: .database)
                    break
                }
            }
            
            // 更新存儲的數據庫版本
            UserDefaults.standard.set(toVersion, forKey: self.databaseVersionKey)
            
            // 記錄日誌
            Logger.info("數據遷移完成: 當前版本 \(toVersion)", category: .database)
            
            // 回調
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
    
    /// 設置遷移狀態
    /// - Parameter migrating: 是否正在遷移
    private func setMigrationStatus(_ migrating: Bool) {
        isMigrating = migrating
        
        // 通知狀態變更
        onMigrationStatusChange?(migrating)
        
        // 記錄日誌
        if migrating {
            Logger.info("開始數據遷移", category: .database)
        } else {
            Logger.info("結束數據遷移", category: .database)
        }
    }
}
