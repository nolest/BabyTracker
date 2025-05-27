import Foundation

/// 備份服務
class BackupService {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = BackupService()
    
    // MARK: - 屬性
    
    /// 備份目錄URL
    private let backupsURL = Constants.Files.backupsURL
    
    /// 上次備份時間的鍵
    private let lastBackupTimeKey = Constants.UserDefaultsKeys.lastBackupTime
    
    /// 是否正在備份
    private(set) var isBackingUp = false
    
    /// 備份狀態變更處理器
    var onBackupStatusChange: ((Bool) -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    init() {
        // 創建備份目錄
        createBackupDirectoryIfNeeded()
    }
    
    // MARK: - 公共方法
    
    /// 創建備份
    /// - Parameters:
    ///   - name: 備份名稱
    ///   - completion: 完成回調
    func createBackup(name: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // 檢查是否正在備份
        guard !isBackingUp else {
            let error = NSError(domain: "BackupService", code: 1, userInfo: [NSLocalizedDescriptionKey: "備份已在進行中"])
            completion(.failure(error))
            return
        }
        
        // 更新備份狀態
        setBackupStatus(true)
        
        // 執行備份
        performBackup(name: name) { result in
            // 更新備份狀態
            self.setBackupStatus(false)
            
            // 回調
            completion(result)
        }
    }
    
    /// 恢復備份
    /// - Parameters:
    ///   - url: 備份文件URL
    ///   - completion: 完成回調
    func restoreBackup(from url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // 檢查是否正在備份
        guard !isBackingUp else {
            let error = NSError(domain: "BackupService", code: 1, userInfo: [NSLocalizedDescriptionKey: "備份已在進行中"])
            completion(.failure(error))
            return
        }
        
        // 更新備份狀態
        setBackupStatus(true)
        
        // 執行恢復
        performRestore(from: url) { result in
            // 更新備份狀態
            self.setBackupStatus(false)
            
            // 回調
            completion(result)
        }
    }
    
    /// 獲取所有備份
    /// - Returns: 備份文件URL列表
    func getAllBackups() -> [URL] {
        do {
            // 獲取備份目錄中的所有文件
            let fileURLs = try FileManager.default.contentsOfDirectory(at: backupsURL, includingPropertiesForKeys: nil)
            
            // 過濾出備份文件
            return fileURLs.filter { $0.pathExtension == "backup" }
        } catch {
            Logger.error("獲取備份列表失敗: \(error.localizedDescription)", category: .app)
            return []
        }
    }
    
    /// 刪除備份
    /// - Parameters:
    ///   - url: 備份文件URL
    ///   - completion: 完成回調
    func deleteBackup(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            // 刪除備份文件
            try FileManager.default.removeItem(at: url)
            
            // 記錄日誌
            Logger.info("刪除備份成功: \(url.lastPathComponent)", category: .app)
            
            // 回調
            completion(.success(()))
        } catch {
            // 記錄日誌
            Logger.error("刪除備份失敗: \(error.localizedDescription)", category: .app)
            
            // 回調
            completion(.failure(error))
        }
    }
    
    /// 獲取上次備份時間
    /// - Returns: 上次備份時間
    func getLastBackupTime() -> Date? {
        return UserDefaults.standard.object(forKey: lastBackupTimeKey) as? Date
    }
    
    // MARK: - 私有方法
    
    /// 創建備份目錄
    private func createBackupDirectoryIfNeeded() {
        do {
            // 檢查備份目錄是否存在
            if !FileManager.default.fileExists(atPath: backupsURL.path) {
                // 創建備份目錄
                try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
                
                // 記錄日誌
                Logger.info("創建備份目錄成功", category: .app)
            }
        } catch {
            // 記錄日誌
            Logger.error("創建備份目錄失敗: \(error.localizedDescription)", category: .app)
        }
    }
    
    /// 執行備份
    /// - Parameters:
    ///   - name: 備份名稱
    ///   - completion: 完成回調
    private func performBackup(name: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // 模擬備份過程
        DispatchQueue.global().async {
            // 模擬延遲
            Thread.sleep(forTimeInterval: 2.0)
            
            // 創建備份文件名
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "\(name)_\(dateString).backup"
            
            // 創建備份文件URL
            let backupURL = self.backupsURL.appendingPathComponent(fileName)
            
            // 創建備份文件
            do {
                // 創建示例備份數據
                let backupData = "This is a backup file".data(using: .utf8)!
                
                // 寫入備份文件
                try backupData.write(to: backupURL)
                
                // 更新上次備份時間
                let now = Date()
                UserDefaults.standard.set(now, forKey: self.lastBackupTimeKey)
                
                // 記錄日誌
                Logger.info("備份成功: \(fileName)", category: .app)
                
                // 回調
                DispatchQueue.main.async {
                    completion(.success(backupURL))
                }
            } catch {
                // 記錄日誌
                Logger.error("備份失敗: \(error.localizedDescription)", category: .app)
                
                // 回調
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 執行恢復
    /// - Parameters:
    ///   - url: 備份文件URL
    ///   - completion: 完成回調
    private func performRestore(from url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // 模擬恢復過程
        DispatchQueue.global().async {
            // 模擬延遲
            Thread.sleep(forTimeInterval: 3.0)
            
            // 檢查備份文件是否存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                // 回調
                DispatchQueue.main.async {
                    let error = NSError(domain: "BackupService", code: 2, userInfo: [NSLocalizedDescriptionKey: "備份文件不存在"])
                    completion(.failure(error))
                }
                return
            }
            
            // 記錄日誌
            Logger.info("恢復備份成功: \(url.lastPathComponent)", category: .app)
            
            // 回調
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
    
    /// 設置備份狀態
    /// - Parameter backingUp: 是否正在備份
    private func setBackupStatus(_ backingUp: Bool) {
        isBackingUp = backingUp
        
        // 通知狀態變更
        onBackupStatusChange?(backingUp)
        
        // 記錄日誌
        if backingUp {
            Logger.info("開始備份", category: .app)
        } else {
            Logger.info("結束備份", category: .app)
        }
    }
}
