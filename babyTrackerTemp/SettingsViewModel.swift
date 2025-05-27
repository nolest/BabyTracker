import Foundation
import Combine

/// 設置視圖模型
class SettingsViewModel {
    // MARK: - 類型
    
    /// 設置項類型
    enum SettingItemType {
        case toggle(isOn: Bool)
        case navigation
        case info(detail: String)
        case action
    }
    
    /// 設置項
    struct SettingsItem {
        let title: String
        let type: SettingItemType
        let identifier: String
    }
    
    /// 設置分區
    struct SettingsSection {
        let title: String
        let footer: String?
        var items: [SettingsItem]
    }
    
    // MARK: - 屬性
    
    /// 用戶設置
    private let userSettings: UserSettings
    
    /// 網絡監視器
    private let networkMonitor: NetworkMonitor
    
    /// 設置分區
    private(set) var sections: [SettingsSection]
    
    /// 取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - userSettings: 用戶設置
    ///   - networkMonitor: 網絡監視器
    init(userSettings: UserSettings, networkMonitor: NetworkMonitor) {
        self.userSettings = userSettings
        self.networkMonitor = networkMonitor
        
        // 初始化設置分區
        self.sections = [
            // 寶寶信息分區
            SettingsSection(
                title: "寶寶信息",
                footer: nil,
                items: [
                    SettingsItem(
                        title: "寶寶檔案",
                        type: .navigation,
                        identifier: "babyProfile"
                    )
                ]
            ),
            
            // 通知分區
            SettingsSection(
                title: "通知",
                footer: nil,
                items: [
                    SettingsItem(
                        title: "通知設置",
                        type: .navigation,
                        identifier: "notifications"
                    ),
                    SettingsItem(
                        title: "餵食提醒",
                        type: .toggle(isOn: userSettings.feedingRemindersEnabled),
                        identifier: "feedingReminders"
                    ),
                    SettingsItem(
                        title: "睡眠提醒",
                        type: .toggle(isOn: userSettings.sleepRemindersEnabled),
                        identifier: "sleepReminders"
                    ),
                    SettingsItem(
                        title: "換尿布提醒",
                        type: .toggle(isOn: userSettings.diaperRemindersEnabled),
                        identifier: "diaperReminders"
                    )
                ]
            ),
            
            // AI設置分區
            SettingsSection(
                title: "AI分析設置",
                footer: "啟用雲端AI分析可獲得更準確的睡眠模式分析和個性化建議",
                items: [
                    SettingsItem(
                        title: "AI設置",
                        type: .navigation,
                        identifier: "aiSettings"
                    ),
                    SettingsItem(
                        title: "啟用雲端AI分析",
                        type: .toggle(isOn: userSettings.cloudAIEnabled),
                        identifier: "cloudAI"
                    ),
                    SettingsItem(
                        title: "僅在Wi-Fi下使用雲端分析",
                        type: .toggle(isOn: userSettings.cloudAIOnlyOnWifi),
                        identifier: "cloudAIOnlyOnWifi"
                    ),
                    SettingsItem(
                        title: "匿名化數據",
                        type: .toggle(isOn: userSettings.anonymizeData),
                        identifier: "anonymizeData"
                    )
                ]
            ),
            
            // 數據管理分區
            SettingsSection(
                title: "數據管理",
                footer: nil,
                items: [
                    SettingsItem(
                        title: "數據管理",
                        type: .navigation,
                        identifier: "dataManagement"
                    ),
                    SettingsItem(
                        title: "自動備份",
                        type: .toggle(isOn: userSettings.autoBackupEnabled),
                        identifier: "autoBackup"
                    ),
                    SettingsItem(
                        title: "上次備份時間",
                        type: .info(detail: formatLastBackupDate()),
                        identifier: "lastBackup"
                    )
                ]
            ),
            
            // 關於分區
            SettingsSection(
                title: "關於",
                footer: nil,
                items: [
                    SettingsItem(
                        title: "關於應用",
                        type: .navigation,
                        identifier: "about"
                    ),
                    SettingsItem(
                        title: "發送反饋",
                        type: .action,
                        identifier: "feedback"
                    ),
                    SettingsItem(
                        title: "評分應用",
                        type: .action,
                        identifier: "rateApp"
                    ),
                    SettingsItem(
                        title: "分享應用",
                        type: .action,
                        identifier: "shareApp"
                    ),
                    SettingsItem(
                        title: "版本",
                        type: .info(detail: getAppVersion()),
                        identifier: "version"
                    )
                ]
            )
        ]
        
        // 監聽網絡狀態變化
        setupNetworkMonitoring()
    }
    
    // MARK: - 公共方法
    
    /// 切換設置
    /// - Parameters:
    ///   - indexPath: 索引路徑
    ///   - isOn: 是否開啟
    func toggleSetting(at indexPath: IndexPath, isOn: Bool) {
        let item = sections[indexPath.section].items[indexPath.row]
        
        switch item.identifier {
        case "feedingReminders":
            userSettings.feedingRemindersEnabled = isOn
            
        case "sleepReminders":
            userSettings.sleepRemindersEnabled = isOn
            
        case "diaperReminders":
            userSettings.diaperRemindersEnabled = isOn
            
        case "cloudAI":
            userSettings.cloudAIEnabled = isOn
            
        case "cloudAIOnlyOnWifi":
            userSettings.cloudAIOnlyOnWifi = isOn
            
        case "anonymizeData":
            userSettings.anonymizeData = isOn
            
        case "autoBackup":
            userSettings.autoBackupEnabled = isOn
            
        default:
            break
        }
        
        // 更新設置項
        updateSettingItem(at: indexPath)
    }
    
    // MARK: - 私有方法
    
    /// 設置網絡監視
    private func setupNetworkMonitoring() {
        networkMonitor.networkStatusPublisher
            .sink { [weak self] status in
                // 如果網絡狀態變為無連接，且用戶設置為僅在Wi-Fi下使用雲端分析
                if status == .notConnected && self?.userSettings.cloudAIOnlyOnWifi == true {
                    // 更新雲端AI設置項
                    self?.updateCloudAISettingItems()
                }
                
                // 如果網絡狀態變為Wi-Fi，且用戶設置為僅在Wi-Fi下使用雲端分析
                if status == .wifi && self?.userSettings.cloudAIOnlyOnWifi == true {
                    // 更新雲端AI設置項
                    self?.updateCloudAISettingItems()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 更新設置項
    /// - Parameter indexPath: 索引路徑
    private func updateSettingItem(at indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        
        switch item.identifier {
        case "feedingReminders":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .toggle(isOn: userSettings.feedingRemindersEnabled),
                identifier: item.identifier
            )
            
        case "sleepReminders":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .toggle(isOn: userSettings.sleepRemindersEnabled),
                identifier: item.identifier
            )
            
        case "diaperReminders":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .toggle(isOn: userSettings.diaperRemindersEnabled),
                identifier: item.identifier
            )
            
        case "cloudAI":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .toggle(isOn: userSettings.cloudAIEnabled),
                identifier: item.identifier
            )
            
        case "cloudAIOnlyOnWifi":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .toggle(isOn: userSettings.cloudAIOnlyOnWifi),
                identifier: item.identifier
            )
            
        case "anonymizeData":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .toggle(isOn: userSettings.anonymizeData),
                identifier: item.identifier
            )
            
        case "autoBackup":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .toggle(isOn: userSettings.autoBackupEnabled),
                identifier: item.identifier
            )
            
        case "lastBackup":
            sections[indexPath.section].items[indexPath.row] = SettingsItem(
                title: item.title,
                type: .info(detail: formatLastBackupDate()),
                identifier: item.identifier
            )
            
        default:
            break
        }
    }
    
    /// 更新雲端AI設置項
    private func updateCloudAISettingItems() {
        // 查找AI設置分區
        if let sectionIndex = sections.firstIndex(where: { $0.title == "AI分析設置" }) {
            // 查找雲端AI設置項
            if let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.identifier == "cloudAI" }) {
                // 更新雲端AI設置項
                sections[sectionIndex].items[itemIndex] = SettingsItem(
                    title: "啟用雲端AI分析",
                    type: .toggle(isOn: userSettings.cloudAIEnabled),
                    identifier: "cloudAI"
                )
            }
        }
    }
    
    /// 格式化最後備份日期
    /// - Returns: 格式化後的日期字符串
    private func formatLastBackupDate() -> String {
        if let lastBackupDate = userSettings.lastBackupDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: lastBackupDate)
        } else {
            return "從未備份"
        }
    }
    
    /// 獲取應用版本
    /// - Returns: 應用版本字符串
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        } else {
            return "未知"
        }
    }
}
