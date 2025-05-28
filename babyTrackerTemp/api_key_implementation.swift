// APIKeyManager.swift
// 寶寶生活記錄專業版（Baby Tracker）
// API Key管理實現

import Foundation
import Security
import CommonCrypto

/// API Key管理器，負責安全存儲和獲取API Key
class APIKeyManager {
    // MARK: - 單例
    static let shared = APIKeyManager()
    private init() {
        setupInitialKey()
    }
    
    // MARK: - 常量
    // 注意：實際生產環境中，這些值會被混淆處理
    private let keyPart1 = "sk-aefd" // API Key的第一部分（示例）
    private let keyResourceName = "api_config"
    private let keychainIdentifier = "com.babytracker.apikey.part3"
    
    // MARK: - 公共方法
    
    /// 獲取完整的API Key
    func getAPIKey() -> String {
        return assembleAPIKey()
    }
    
    /// 重置API Key（僅用於測試）
    func resetAPIKey(with newKey: String) {
        guard newKey.hasPrefix("sk-") else {
            print("Invalid API key format")
            return
        }
        
        // 分割新的Key
        let parts = splitAPIKey(newKey)
        
        // 存儲第三部分到Keychain
        saveToKeychain(value: parts.part3, forKey: keychainIdentifier)
        
        // 注意：在實際應用中，part1和part2的更新需要通過應用更新或遠程配置
        print("API Key has been reset (in production, only part3 would be updated)")
    }
    
    // MARK: - 私有方法
    
    /// 組裝完整的API Key
    private func assembleAPIKey() -> String {
        let part1 = keyPart1
        let part2 = getKeyPart2()
        let part3 = getKeyPart3()
        
        // 使用設備特定信息作為組合因子
        let deviceFactor = generateDeviceFactor()
        return combineKeyParts(part1: part1, part2: part2, part3: part3, deviceFactor: deviceFactor)
    }
    
    /// 獲取API Key的第二部分（從加密資源）
    private func getKeyPart2() -> String {
        // 在實際應用中，這會從加密資源文件中讀取
        // 這裡使用模擬實現
        return "76903"
    }
    
    /// 獲取API Key的第三部分（從Keychain）
    private func getKeyPart3() -> String {
        if let storedValue = retrieveFromKeychain(forKey: keychainIdentifier) {
            return storedValue
        }
        
        // 如果Keychain中沒有，返回默認值（實際應用中不應該有默認值）
        return "1e0449886814d5403b028f3"
    }
    
    /// 生成設備特定的組合因子
    private func generateDeviceFactor() -> String {
        // 在實際應用中，這會使用設備特定信息
        // 這裡使用模擬實現
        return "device_factor"
    }
    
    /// 組合API Key的各個部分
    private func combineKeyParts(part1: String, part2: String, part3: String, deviceFactor: String) -> String {
        // 在實際應用中，這會使用更複雜的組合邏輯
        // 這裡使用簡單的直接組合
        return part1 + part2 + part3
    }
    
    /// 分割API Key為三個部分（用於重置）
    private func splitAPIKey(_ apiKey: String) -> (part1: String, part2: String, part3: String) {
        // 簡單的分割邏輯，實際應用中會更複雜
        let length = apiKey.count
        let part1Length = 6 // "sk-aefd"
        let part2Length = 5 // "76903"
        
        let part1 = String(apiKey.prefix(part1Length))
        let part2Start = apiKey.index(apiKey.startIndex, offsetBy: part1Length)
        let part2End = apiKey.index(part2Start, offsetBy: part2Length)
        let part2 = String(apiKey[part2Start..<part2End])
        let part3 = String(apiKey[part2End...])
        
        return (part1, part2, part3)
    }
    
    /// 初始設置API Key
    private func setupInitialKey() {
        // 檢查Keychain中是否已有值
        if retrieveFromKeychain(forKey: keychainIdentifier) == nil {
            // 使用提供的API Key進行初始設置
            let initialKey = "sk-aefd769031e0449886814d5403b028f3"
            let parts = splitAPIKey(initialKey)
            saveToKeychain(value: parts.part3, forKey: keychainIdentifier)
        }
    }
    
    // MARK: - Keychain操作
    
    /// 保存值到Keychain
    private func saveToKeychain(value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // 準備查詢字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 先刪除可能存在的舊值
        SecItemDelete(query as CFDictionary)
        
        // 添加新值
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 從Keychain中檢索值
    private func retrieveFromKeychain(forKey key: String) -> String? {
        // 準備查詢字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        }
        
        return nil
    }
}

// MARK: - 設備標識

/// 設備標識工具，用於生成設備指紋和安裝ID
class DeviceIdentifier {
    // MARK: - 單例
    static let shared = DeviceIdentifier()
    private init() {}
    
    // MARK: - 常量
    private let installationIDKey = "com.babytracker.installation_id"
    
    // MARK: - 公共方法
    
    /// 獲取設備指紋
    func getDeviceFingerprint() -> String {
        // 組合多個設備特徵
        // 注意：實際應用中會使用更多設備特徵
        let deviceName = UIDevice.current.name
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        // 創建唯一指紋
        let fingerprintString = "\(deviceName)|\(deviceModel)|\(systemVersion)|\(identifierForVendor)"
        return fingerprintString.sha256()
    }
    
    /// 獲取安裝ID
    func getInstallationID() -> String {
        // 檢查是否已存在
        if let existingID = UserDefaults.standard.string(forKey: installationIDKey) {
            return existingID
        }
        
        // 創建新ID
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: installationIDKey)
        return newID
    }
}

// MARK: - 字符串擴展

extension String {
    /// 計算字符串的SHA-256哈希
    func sha256() -> String {
        if let stringData = self.data(using: .utf8) {
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            stringData.withUnsafeBytes {
                _ = CC_SHA256($0.baseAddress, CC_LONG(stringData.count), &digest)
            }
            return digest.map { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
}

// MARK: - 請求簽名

/// 生成請求簽名
func generateRequestSignature(timestamp: String, deviceFingerprint: String) -> String {
    let installationID = DeviceIdentifier.shared.getInstallationID()
    let signatureBase = "\(timestamp)|\(deviceFingerprint)|\(installationID)"
    return signatureBase.sha256()
}
