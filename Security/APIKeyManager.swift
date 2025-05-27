import Foundation
import Security

/// API密鑰管理器
class APIKeyManager {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = APIKeyManager()
    
    // MARK: - 屬性
    
    /// API密鑰列表
    private let apiKeys = [
        "sk_deepseek_01a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t",
        "sk_deepseek_9s8r7q6p5o4n3m2l1k0j9i8h7g6f5e4d3c2b1a0",
        "sk_deepseek_2a4b6c8d0e2f4g6h8i0j2k4l6m8n0o2p4q6r8s0t"
    ]
    
    /// 用於存儲API密鑰的鑰匙串服務名稱
    private let keychainService = "com.babytracker.apikey"
    
    /// 用於存儲API密鑰的鑰匙串賬戶名稱
    private let keychainAccount = "deepseekAPIKey"
    
    /// 設備標識符
    private let deviceIdentifier: DeviceIdentifier
    
    // MARK: - 初始化
    
    /// 初始化方法
    init(deviceIdentifier: DeviceIdentifier = DeviceIdentifier.shared) {
        self.deviceIdentifier = deviceIdentifier
    }
    
    // MARK: - 公共方法
    
    /// 獲取API密鑰
    /// - Returns: API密鑰
    func getAPIKey() -> String {
        // 嘗試從鑰匙串中獲取API密鑰
        if let apiKey = retrieveAPIKeyFromKeychain() {
            return apiKey
        }
        
        // 如果鑰匙串中沒有API密鑰，則根據設備ID選擇一個並保存到鑰匙串
        let apiKey = selectAPIKeyBasedOnDeviceID()
        saveAPIKeyToKeychain(apiKey)
        
        return apiKey
    }
    
    /// 重置API密鑰
    func resetAPIKey() {
        // 從鑰匙串中刪除API密鑰
        deleteAPIKeyFromKeychain()
        
        // 重新選擇API密鑰並保存到鑰匙串
        let apiKey = selectAPIKeyBasedOnDeviceID()
        saveAPIKeyToKeychain(apiKey)
    }
    
    // MARK: - 私有方法
    
    /// 根據設備ID選擇API密鑰
    /// - Returns: API密鑰
    private func selectAPIKeyBasedOnDeviceID() -> String {
        // 獲取設備ID的哈希值
        let deviceIDHash = deviceIdentifier.getDeviceIdentifierHash()
        
        // 使用哈希值對API密鑰列表的長度取模，得到索引
        let index = abs(deviceIDHash) % apiKeys.count
        
        return apiKeys[index]
    }
    
    /// 從鑰匙串中獲取API密鑰
    /// - Returns: API密鑰
    private func retrieveAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    /// 保存API密鑰到鑰匙串
    /// - Parameter apiKey: API密鑰
    private func saveAPIKeyToKeychain(_ apiKey: String) {
        guard let data = apiKey.data(using: .utf8) else {
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        
        // 嘗試更新現有項目
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        
        // 如果項目不存在，則添加新項目
        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        if status != errSecSuccess {
            Logger.error("無法保存API密鑰到鑰匙串: \(status)", category: .security)
        }
    }
    
    /// 從鑰匙串中刪除API密鑰
    private func deleteAPIKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            Logger.error("無法從鑰匙串中刪除API密鑰: \(status)", category: .security)
        }
    }
}
