import Foundation

/// 原生KeychainServices API的簡單封裝，替代KeychainSwift功能
class KeychainManager {
    
    // MARK: - 錯誤類型
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }
    
    // MARK: - 保存數據
    static func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // 先刪除可能存在的舊數據
        SecItemDelete(query as CFDictionary)
        
        // 保存新數據
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - 讀取數據
    static func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }
        
        return data
    }
    
    // MARK: - 刪除數據
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - 便捷方法：保存字符串
    static func saveString(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        try save(key: key, data: data)
    }
    
    // MARK: - 便捷方法：讀取字符串
    static func loadString(forKey key: String) throws -> String {
        let data = try load(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        return string
    }
    
    // MARK: - 便捷方法：檢查鑰匙串中是否存在指定鍵
    static func containsKey(_ key: String) -> Bool {
        do {
            _ = try load(key: key)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - 便捷方法：API密鑰管理
    static func saveAPIKey(_ apiKey: String) throws {
        try saveString(apiKey, forKey: "deepseek_api_key")
    }
    
    static func getAPIKey() throws -> String {
        return try loadString(forKey: "deepseek_api_key")
    }
    
    static func deleteAPIKey() throws {
        try delete(key: "deepseek_api_key")
    }
}
