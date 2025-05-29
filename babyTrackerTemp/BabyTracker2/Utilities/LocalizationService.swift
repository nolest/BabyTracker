import Foundation

class LocalizationService {
    static let shared = LocalizationService()
    
    private var bundle: Bundle
    private var languageCode: String
    
    private init() {
        self.languageCode = UserDefaults.standard.string(forKey: "language") ?? "en"
        
        // 獲取對應語言的Bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
    }
    
    func setLanguage(_ languageCode: String) {
        self.languageCode = languageCode
        UserDefaults.standard.set(languageCode, forKey: "language")
        
        // 更新Bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        }
        
        // 發送通知，通知應用語言已更改
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
    
    func localizedString(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

// 擴展String以支持本地化
extension String {
    var localized: String {
        return LocalizationService.shared.localizedString(for: self)
    }
}
