import Foundation

/// 常量類
struct Constants {
    // MARK: - 應用常量
    
    /// 應用常量
    struct App {
        /// 應用名稱
        static let name = "寶寶生活記錄"
        
        /// 應用版本
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        /// 應用構建版本
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        /// 應用包標識符
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.babytracker"
    }
    
    // MARK: - 用戶默認值鍵
    
    /// 用戶默認值鍵
    struct UserDefaultsKeys {
        /// 選中的寶寶ID
        static let selectedBabyId = "selectedBabyId"
        
        /// 是否首次啟動
        static let isFirstLaunch = "isFirstLaunch"
        
        /// 是否啟用雲端AI分析
        static let isCloudAIEnabled = "isCloudAIEnabled"
        
        /// 是否啟用AI分析
        static let isAIAnalysisEnabled = "isAIAnalysisEnabled"
        
        /// 是否啟用數據匿名化
        static let isDataAnonymizationEnabled = "isDataAnonymizationEnabled"
        
        /// 是否啟用通知
        static let isNotificationEnabled = "isNotificationEnabled"
        
        /// 上次同步時間
        static let lastSyncTime = "lastSyncTime"
        
        /// 上次備份時間
        static let lastBackupTime = "lastBackupTime"
        
        /// 主題
        static let theme = "theme"
        
        /// 語言
        static let language = "language"
    }
    
    // MARK: - 通知名稱
    
    /// 通知名稱
    struct NotificationNames {
        /// 寶寶數據更新
        static let babyDataUpdated = Notification.Name("babyDataUpdated")
        
        /// 睡眠記錄更新
        static let sleepRecordUpdated = Notification.Name("sleepRecordUpdated")
        
        /// 餵食記錄更新
        static let feedingRecordUpdated = Notification.Name("feedingRecordUpdated")
        
        /// 活動記錄更新
        static let activityUpdated = Notification.Name("activityUpdated")
        
        /// 成長記錄更新
        static let growthUpdated = Notification.Name("growthUpdated")
        
        /// 網絡狀態變更
        static let networkStatusChanged = Notification.Name("networkStatusChanged")
        
        /// 用戶設置更新
        static let userSettingsUpdated = Notification.Name("userSettingsUpdated")
        
        /// AI分析完成
        static let aiAnalysisCompleted = Notification.Name("aiAnalysisCompleted")
    }
    
    // MARK: - 錯誤域
    
    /// 錯誤域
    struct ErrorDomains {
        /// 網絡錯誤域
        static let network = "com.babytracker.error.network"
        
        /// 倉庫錯誤域
        static let repository = "com.babytracker.error.repository"
        
        /// 分析錯誤域
        static let analysis = "com.babytracker.error.analysis"
        
        /// 雲端錯誤域
        static let cloud = "com.babytracker.error.cloud"
        
        /// 安全錯誤域
        static let security = "com.babytracker.error.security"
    }
    
    // MARK: - 時間常量
    
    /// 時間常量
    struct Time {
        /// 一分鐘（秒）
        static let oneMinute: TimeInterval = 60
        
        /// 一小時（秒）
        static let oneHour: TimeInterval = 3600
        
        /// 一天（秒）
        static let oneDay: TimeInterval = 86400
        
        /// 一週（秒）
        static let oneWeek: TimeInterval = 604800
        
        /// 一個月（秒，30天）
        static let oneMonth: TimeInterval = 2592000
    }
    
    // MARK: - 文件常量
    
    /// 文件常量
    struct Files {
        /// 文檔目錄URL
        static let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        /// 緩存目錄URL
        static let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        /// 臨時目錄URL
        static let tempURL = FileManager.default.temporaryDirectory
        
        /// 備份目錄URL
        static let backupsURL = documentsURL.appendingPathComponent("Backups")
        
        /// 日誌文件URL
        static let logFileURL = documentsURL.appendingPathComponent("BabyTracker.log")
    }
    
    // MARK: - 網絡常量
    
    /// 網絡常量
    struct Network {
        /// 請求超時時間
        static let requestTimeout: TimeInterval = 30
        
        /// 最大重試次數
        static let maxRetryCount = 3
        
        /// 重試間隔（秒）
        static let retryInterval: TimeInterval = 2
    }
    
    // MARK: - AI常量
    
    /// AI常量
    struct AI {
        /// 每小時最大請求次數
        static let maxRequestsPerHour = 10
        
        /// 每天最大請求次數
        static let maxRequestsPerDay = 30
        
        /// 緩存有效期（秒）
        static let cacheValidityDuration: TimeInterval = 3600
    }
    
    // MARK: - UI常量
    
    /// UI常量
    struct UI {
        /// 標準間距
        static let standardSpacing: CGFloat = 16
        
        /// 小間距
        static let smallSpacing: CGFloat = 8
        
        /// 大間距
        static let largeSpacing: CGFloat = 24
        
        /// 標準圓角半徑
        static let standardCornerRadius: CGFloat = 8
        
        /// 標準動畫持續時間
        static let standardAnimationDuration: TimeInterval = 0.3
    }
}
