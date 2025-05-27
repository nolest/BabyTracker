// UserSettings.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：Deepseek API整合
// 用戶設置管理

import Foundation
import Security

/// 管理用戶設置，特別是與雲端AI分析相關的設置
class UserSettings {
    // MARK: - 單例模式
    static let shared = UserSettings()
    
    private init() {
        // 從持久化存儲加載設置
        loadSettings()
    }
    
    // MARK: - 設置鍵
    private enum SettingsKeys {
        static let isCloudAnalysisEnabled = "isCloudAnalysisEnabled"
        static let useCloudAnalysisOnlyOnWiFi = "useCloudAnalysisOnlyOnWiFi"
        static let deepseekAPIKeyIdentifier = "com.babytracker.deepseekAPIKey"
    }
    
    // MARK: - 公開屬性
    
    /// 是否啟用雲端分析
    var isCloudAnalysisEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SettingsKeys.isCloudAnalysisEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsKeys.isCloudAnalysisEnabled)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 是否僅在WiFi環境下使用雲端分析
    var useCloudAnalysisOnlyOnWiFi: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SettingsKeys.useCloudAnalysisOnlyOnWiFi)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsKeys.useCloudAnalysisOnlyOnWiFi)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 獲取Deepseek API Key
    var deepseekAPIKey: String? {
        get {
            return getAPIKeyFromKeychain()
        }
        set {
            if let newValue = newValue {
                saveAPIKeyToKeychain(newValue)
            } else {
                deleteAPIKeyFromKeychain()
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 從持久化存儲加載設置
    private func loadSettings() {
        // 如果設置不存在，設置默認值
        if !UserDefaults.standard.contains(key: SettingsKeys.isCloudAnalysisEnabled) {
            isCloudAnalysisEnabled = false
        }
        
        if !UserDefaults.standard.contains(key: SettingsKeys.useCloudAnalysisOnlyOnWiFi) {
            useCloudAnalysisOnlyOnWiFi = true
        }
    }
    
    // MARK: - Keychain操作
    
    /// 從Keychain獲取API Key
    private func getAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: SettingsKeys.deepseekAPIKeyIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    /// 保存API Key到Keychain
    private func saveAPIKeyToKeychain(_ apiKey: String) {
        // 首先嘗試刪除現有的API Key
        deleteAPIKeyFromKeychain()
        
        // 然後保存新的API Key
        guard let data = apiKey.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: SettingsKeys.deepseekAPIKeyIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// 從Keychain刪除API Key
    private func deleteAPIKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: SettingsKeys.deepseekAPIKeyIdentifier
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - UserDefaults擴展
extension UserDefaults {
    /// 檢查UserDefaults中是否包含指定的鍵
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
