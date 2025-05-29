import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    @Published var language: String = "en" {
        didSet {
            UserDefaults.standard.set(language, forKey: "language")
            LocalizationService.shared.setLanguage(language)
        }
    }
    
    @Published var aiEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(aiEnabled, forKey: "aiEnabled")
        }
    }
    
    private init() {
        // 初始化isDarkMode
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        // 初始化language
        let savedLanguage = UserDefaults.standard.string(forKey: "language")
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let defaultLanguage: String
        
        if preferredLanguage.contains("zh-Hant") {
            defaultLanguage = "zh-Hant"
        } else if preferredLanguage.contains("zh-Hans") {
            defaultLanguage = "zh-Hans"
        } else {
            defaultLanguage = "en"
        }
        
        self.language = savedLanguage ?? defaultLanguage
        
        if savedLanguage == nil {
            UserDefaults.standard.set(defaultLanguage, forKey: "language")
        }
        
        // 初始化aiEnabled
        let aiEnabledExists = UserDefaults.standard.contains(key: "aiEnabled")
        self.aiEnabled = UserDefaults.standard.bool(forKey: "aiEnabled")
        
        if !aiEnabledExists {
            // 默認啟用AI功能
            self.aiEnabled = true
            UserDefaults.standard.set(true, forKey: "aiEnabled")
        }
        
        // 設置語言
        LocalizationService.shared.setLanguage(self.language)
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
