import UIKit

/// 設備標識符
class DeviceIdentifier {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = DeviceIdentifier()
    
    // MARK: - 屬性
    
    /// 設備唯一標識符
    private var deviceIdentifier: String?
    
    /// 用於存儲設備標識符的鑰匙串服務名稱
    private let keychainService = "com.babytracker.deviceid"
    
    /// 用於存儲設備標識符的鑰匙串賬戶名稱
    private let keychainAccount = "deviceIdentifier"
    
    // MARK: - 初始化
    
    /// 私有初始化方法
    private init() {
        // 嘗試從鑰匙串中獲取設備標識符
        deviceIdentifier = retrieveDeviceIdentifierFromKeychain()
        
        // 如果鑰匙串中沒有設備標識符，則生成一個新的並保存到鑰匙串
        if deviceIdentifier == nil {
            deviceIdentifier = generateDeviceIdentifier()
            saveDeviceIdentifierToKeychain(deviceIdentifier!)
        }
    }
    
    // MARK: - 公共方法
    
    /// 獲取設備標識符
    /// - Returns: 設備標識符
    func getDeviceIdentifier() -> String {
        return deviceIdentifier ?? generateDeviceIdentifier()
    }
    
    /// 獲取設備標識符的哈希值
    /// - Returns: 設備標識符的哈希值
    func getDeviceIdentifierHash() -> Int {
        return getDeviceIdentifier().hash
    }
    
    /// 重置設備標識符
    func resetDeviceIdentifier() {
        deviceIdentifier = generateDeviceIdentifier()
        saveDeviceIdentifierToKeychain(deviceIdentifier!)
    }
    
    // MARK: - 私有方法
    
    /// 生成設備標識符
    /// - Returns: 設備標識符
    private func generateDeviceIdentifier() -> String {
        // 使用多個設備信息生成唯一標識符
        var identifierComponents = [String]()
        
        // 添加設備名稱
        identifierComponents.append(UIDevice.current.name)
        
        // 添加設備型號
        identifierComponents.append(UIDevice.current.model)
        
        // 添加系統版本
        identifierComponents.append(UIDevice.current.systemVersion)
        
        // 添加設備UUID
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            identifierComponents.append(uuid)
        }
        
        // 添加時間戳
        identifierComponents.append(String(Date().timeIntervalSince1970))
        
        // 添加隨機數
        identifierComponents.append(String(arc4random()))
        
        // 將所有組件連接起來並計算SHA256哈希
        let combinedString = identifierComponents.joined(separator: "-")
        return combinedString.sha256
    }
    
    /// 從鑰匙串中獲取設備標識符
    /// - Returns: 設備標識符
    private func retrieveDeviceIdentifierFromKeychain() -> String? {
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
              let identifier = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return identifier
    }
    
    /// 保存設備標識符到鑰匙串
    /// - Parameter identifier: 設備標識符
    private func saveDeviceIdentifierToKeychain(_ identifier: String) {
        guard let data = identifier.data(using: .utf8) else {
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
            Logger.error("無法保存設備標識符到鑰匙串: \(status)", category: .security)
        }
    }
}

// 為了支持哈希函數，需要導入CommonCrypto
import CommonCrypto
