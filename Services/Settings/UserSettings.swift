import Foundation

/// 用戶設置
class UserSettings {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = UserSettings()
    
    // MARK: - 屬性
    
    /// 是否啟用雲端AI分析
    var isCloudAIEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isCloudAIEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.isCloudAIEnabled)
            notifySettingsChanged()
        }
    }
    
    /// 是否啟用AI分析
    var isAIAnalysisEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isAIAnalysisEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.isAIAnalysisEnabled)
            notifySettingsChanged()
        }
    }
    
    /// 是否使用雲端分析
    var useCloudAnalysis: Bool {
        get {
            return isCloudAIEnabled
        }
    }
    
    /// 是否啟用數據匿名化
    var isDataAnonymizationEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isDataAnonymizationEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.isDataAnonymizationEnabled)
            notifySettingsChanged()
        }
    }
    
    /// 是否啟用通知
    var isNotificationEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isNotificationEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.isNotificationEnabled)
            notifySettingsChanged()
        }
    }
    
    /// 主題
    var theme: Theme {
        get {
            let themeString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.theme) ?? Theme.system.rawValue
            return Theme(rawValue: themeString) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Constants.UserDefaultsKeys.theme)
            notifySettingsChanged()
        }
    }
    
    /// 語言
    var language: Language {
        get {
            let languageString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.language) ?? Language.system.rawValue
            return Language(rawValue: languageString) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Constants.UserDefaultsKeys.language)
            notifySettingsChanged()
        }
    }
    
    /// 選中的寶寶ID
    var selectedBabyId: String? {
        get {
            return UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedBabyId)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.selectedBabyId)
            notifySettingsChanged()
        }
    }
    
    // MARK: - 主題
    
    /// 主題
    enum Theme: String {
        /// 系統
        case system = "system"
        
        /// 淺色
        case light = "light"
        
        /// 深色
        case dark = "dark"
    }
    
    // MARK: - 語言
    
    /// 語言
    enum Language: String {
        /// 系統
        case system = "system"
        
        /// 繁體中文
        case zhHant = "zh-Hant"
        
        /// 簡體中文
        case zhHans = "zh-Hans"
        
        /// 英文
        case en = "en"
    }
    
    // MARK: - 初始化
    
    /// 初始化方法
    init() {
        setupDefaultSettings()
    }
    
    // MARK: - 公共方法
    
    /// 重置所有設置
    func resetAllSettings() {
        // 重置設置
        isCloudAIEnabled = false
        isAIAnalysisEnabled = false
        isDataAnonymizationEnabled = true
        isNotificationEnabled = true
        theme = .system
        language = .system
        
        // 通知設置變更
        notifySettingsChanged()
    }
    
    // MARK: - 私有方法
    
    /// 設置默認設置
    private func setupDefaultSettings() {
        // 檢查是否首次啟動
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isFirstLaunch)
        
        if isFirstLaunch {
            // 設置默認值
            isCloudAIEnabled = false
            isAIAnalysisEnabled = false
            isDataAnonymizationEnabled = true
            isNotificationEnabled = true
            theme = .system
            language = .system
            
            // 標記為非首次啟動
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.isFirstLaunch)
        }
    }
    
    /// 通知設置變更
    private func notifySettingsChanged() {
        // 發送通知
        NotificationCenter.default.post(
            name: Constants.NotificationNames.userSettingsUpdated,
            object: nil
        )
        
        // 記錄日誌
        Logger.info("用戶設置已更新", category: .app)
    }
}
