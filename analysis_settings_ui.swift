// analysis_settings_ui.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 分析設置界面實現

import Foundation
import UIKit
import Combine

// MARK: - 分析設置模型

/// 分析設置模型，存儲用戶的分析偏好設置
struct AnalysisSettings: Codable {
    /// 是否啟用雲端分析
    var isCloudAnalysisEnabled: Bool = true
    
    /// 是否僅在WiFi下使用雲端分析
    var useCloudAnalysisOnlyOnWiFi: Bool = true
    
    /// 分析時間範圍（天）
    var analysisTimeRangeDays: Int = 14
    
    /// 睡眠分析敏感度
    var sleepAnalysisSensitivity: AnalysisSensitivity = .medium
    
    /// 作息分析敏感度
    var routineAnalysisSensitivity: AnalysisSensitivity = .medium
    
    /// 預測準確度閾值
    var predictionConfidenceThreshold: Double = 0.7
    
    /// 是否啟用自動分析
    var isAutoAnalysisEnabled: Bool = true
    
    /// 自動分析頻率（小時）
    var autoAnalysisFrequencyHours: Int = 24
    
    /// 是否啟用分析通知
    var isAnalysisNotificationEnabled: Bool = true
    
    /// 是否啟用數據匿名化
    var isDataAnonymizationEnabled: Bool = true
}

/// 分析敏感度枚舉
enum AnalysisSensitivity: String, Codable, CaseIterable {
    /// 低敏感度
    case low = "low"
    /// 中敏感度
    case medium = "medium"
    /// 高敏感度
    case high = "high"
    
    /// 本地化顯示名稱
    var localizedName: String {
        switch self {
        case .low:
            return NSLocalizedString("低", comment: "")
        case .medium:
            return NSLocalizedString("中", comment: "")
        case .high:
            return NSLocalizedString("高", comment: "")
        }
    }
}

// MARK: - 分析設置管理器

/// 分析設置管理器，負責管理和持久化用戶的分析設置
class AnalysisSettingsManager {
    // MARK: - 單例
    
    static let shared = AnalysisSettingsManager()
    
    // MARK: - 屬性
    
    /// 當前設置
    private(set) var settings: AnalysisSettings
    
    /// 設置變更發布者
    private let settingsSubject = PassthroughSubject<AnalysisSettings, Never>()
    
    /// 設置變更發布者
    var settingsPublisher: AnyPublisher<AnalysisSettings, Never> {
        return settingsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 常量
    
    private let settingsKey = "com.babytracker.analysisSettings"
    
    // MARK: - 初始化
    
    private init() {
        // 從UserDefaults加載設置，如果不存在則使用默認設置
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AnalysisSettings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = AnalysisSettings()
        }
    }
    
    // MARK: - 公開方法
    
    /// 更新設置
    /// - Parameter settings: 新設置
    func updateSettings(_ settings: AnalysisSettings) {
        self.settings = settings
        saveSettings()
        settingsSubject.send(settings)
        
        // 發送通知
        NotificationCenter.default.post(name: .analysisSettingsChanged, object: nil)
    }
    
    /// 更新雲端分析啟用狀態
    /// - Parameter enabled: 是否啟用
    func updateCloudAnalysisEnabled(_ enabled: Bool) {
        var newSettings = settings
        newSettings.isCloudAnalysisEnabled = enabled
        updateSettings(newSettings)
    }
    
    /// 更新僅在WiFi下使用雲端分析
    /// - Parameter onlyOnWiFi: 是否僅在WiFi下使用
    func updateUseCloudAnalysisOnlyOnWiFi(_ onlyOnWiFi: Bool) {
        var newSettings = settings
        newSettings.useCloudAnalysisOnlyOnWiFi = onlyOnWiFi
        updateSettings(newSettings)
    }
    
    /// 更新分析時間範圍
    /// - Parameter days: 天數
    func updateAnalysisTimeRange(_ days: Int) {
        var newSettings = settings
        newSettings.analysisTimeRangeDays = days
        updateSettings(newSettings)
    }
    
    /// 更新睡眠分析敏感度
    /// - Parameter sensitivity: 敏感度
    func updateSleepAnalysisSensitivity(_ sensitivity: AnalysisSensitivity) {
        var newSettings = settings
        newSettings.sleepAnalysisSensitivity = sensitivity
        updateSettings(newSettings)
    }
    
    /// 更新作息分析敏感度
    /// - Parameter sensitivity: 敏感度
    func updateRoutineAnalysisSensitivity(_ sensitivity: AnalysisSensitivity) {
        var newSettings = settings
        newSettings.routineAnalysisSensitivity = sensitivity
        updateSettings(newSettings)
    }
    
    /// 更新預測準確度閾值
    /// - Parameter threshold: 閾值
    func updatePredictionConfidenceThreshold(_ threshold: Double) {
        var newSettings = settings
        newSettings.predictionConfidenceThreshold = threshold
        updateSettings(newSettings)
    }
    
    /// 更新自動分析啟用狀態
    /// - Parameter enabled: 是否啟用
    func updateAutoAnalysisEnabled(_ enabled: Bool) {
        var newSettings = settings
        newSettings.isAutoAnalysisEnabled = enabled
        updateSettings(newSettings)
    }
    
    /// 更新自動分析頻率
    /// - Parameter hours: 小時數
    func updateAutoAnalysisFrequency(_ hours: Int) {
        var newSettings = settings
        newSettings.autoAnalysisFrequencyHours = hours
        updateSettings(newSettings)
    }
    
    /// 更新分析通知啟用狀態
    /// - Parameter enabled: 是否啟用
    func updateAnalysisNotificationEnabled(_ enabled: Bool) {
        var newSettings = settings
        newSettings.isAnalysisNotificationEnabled = enabled
        updateSettings(newSettings)
    }
    
    /// 更新數據匿名化啟用狀態
    /// - Parameter enabled: 是否啟用
    func updateDataAnonymizationEnabled(_ enabled: Bool) {
        var newSettings = settings
        newSettings.isDataAnonymizationEnabled = enabled
        updateSettings(newSettings)
    }
    
    /// 重置設置為默認值
    func resetToDefaults() {
        updateSettings(AnalysisSettings())
    }
    
    // MARK: - 私有方法
    
    /// 保存設置到UserDefaults
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
}

// MARK: - 通知名稱擴展

extension Notification.Name {
    /// 分析設置變更通知
    static let analysisSettingsChanged = Notification.Name("analysisSettingsChanged")
}

// MARK: - 分析設置視圖控制器

/// 分析設置視圖控制器，提供用戶設置分析參數的界面
class AnalysisSettingsViewController: UIViewController {
    // MARK: - 屬性
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let settingsManager = AnalysisSettingsManager.shared
    private var settings: AnalysisSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 分段控制器索引
    
    private enum SensitivityIndex: Int {
        case low = 0
        case medium = 1
        case high = 2
        
        var sensitivity: AnalysisSensitivity {
            switch self {
            case .low: return .low
            case .medium: return .medium
            case .high: return .high
            }
        }
        
        static func from(sensitivity: AnalysisSensitivity) -> SensitivityIndex {
            switch sensitivity {
            case .low: return .low
            case .medium: return .medium
            case .high: return .high
            }
        }
    }
    
    // MARK: - 表格分區
    
    private enum Section: Int, CaseIterable {
        case cloudAnalysis
        case analysisParameters
        case autoAnalysis
        case privacy
        
        var headerTitle: String {
            switch self {
            case .cloudAnalysis:
                return NSLocalizedString("雲端分析", comment: "")
            case .analysisParameters:
                return NSLocalizedString("分析參數", comment: "")
            case .autoAnalysis:
                return NSLocalizedString("自動分析", comment: "")
            case .privacy:
                return NSLocalizedString("隱私", comment: "")
            }
        }
        
        var footerTitle: String? {
            switch self {
            case .cloudAnalysis:
                return NSLocalizedString("雲端分析提供更準確的結果，但需要網絡連接。", comment: "")
            case .analysisParameters:
                return NSLocalizedString("調整分析參數以獲得更符合您需求的結果。", comment: "")
            case .autoAnalysis:
                return NSLocalizedString("自動分析將定期分析寶寶的數據，無需手動操作。", comment: "")
            case .privacy:
                return NSLocalizedString("數據匿名化將移除所有可識別的個人信息，確保您的隱私安全。", comment: "")
            }
        }
        
        var rowCount: Int {
            switch self {
            case .cloudAnalysis:
                return CloudAnalysisRow.allCases.count
            case .analysisParameters:
                return AnalysisParametersRow.allCases.count
            case .autoAnalysis:
                return AutoAnalysisRow.allCases.count
            case .privacy:
                return PrivacyRow.allCases.count
            }
        }
    }
    
    // MARK: - 雲端分析行
    
    private enum CloudAnalysisRow: Int, CaseIterable {
        case enableCloudAnalysis
        case onlyOnWiFi
        
        var title: String {
            switch self {
            case .enableCloudAnalysis:
                return NSLocalizedString("啟用雲端分析", comment: "")
            case .onlyOnWiFi:
                return NSLocalizedString("僅在WiFi下使用雲端分析", comment: "")
            }
        }
    }
    
    // MARK: - 分析參數行
    
    private enum AnalysisParametersRow: Int, CaseIterable {
        case timeRange
        case sleepSensitivity
        case routineSensitivity
        case predictionThreshold
        
        var title: String {
            switch self {
            case .timeRange:
                return NSLocalizedString("分析時間範圍", comment: "")
            case .sleepSensitivity:
                return NSLocalizedString("睡眠分析敏感度", comment: "")
            case .routineSensitivity:
                return NSLocalizedString("作息分析敏感度", comment: "")
            case .predictionThreshold:
                return NSLocalizedString("預測準確度閾值", comment: "")
            }
        }
    }
    
    // MARK: - 自動分析行
    
    private enum AutoAnalysisRow: Int, CaseIterable {
        case enableAutoAnalysis
        case frequency
        case enableNotification
        
        var title: String {
            switch self {
            case .enableAutoAnalysis:
                return NSLocalizedString("啟用自動分析", comment: "")
            case .frequency:
                return NSLocalizedString("自動分析頻率", comment: "")
            case .enableNotification:
                return NSLocalizedString("啟用分析通知", comment: "")
            }
        }
    }
    
    // MARK: - 隱私行
    
    private enum PrivacyRow: Int, CaseIterable {
        case enableAnonymization
        
        var title: String {
            switch self {
            case .enableAnonymization:
                return NSLocalizedString("啟用數據匿名化", comment: "")
            }
        }
    }
    
    // MARK: - 初始化
    
    init() {
        self.settings = settingsManager.settings
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.settings = AnalysisSettingsManager.shared.settings
        super.init(coder: coder)
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupNavigationBar()
        bindSettings()
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("分析設置", comment: "")
    }
    
    /// 設置表格視圖
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ValueCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SegmentedCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SliderCell")
    }
    
    /// 設置導航欄
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("重置", comment: ""),
            style: .plain,
            target: self,
            action: #selector(resetButtonTapped)
        )
    }
    
    /// 綁定設置
    private func bindSettings() {
        settingsManager.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    /// 重置按鈕點擊
    @objc private func resetButtonTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("重置設置", comment: ""),
            message: NSLocalizedString("確定要將所有設置重置為默認值嗎？", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("取消", comment: ""),
            style: .cancel
        ))
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("重置", comment: ""),
            style: .destructive,
            handler: { [weak self] _ in
                self?.settingsManager.resetToDefaults()
            }
        ))
        
        present(alert, animated: true)
    }
    
    /// 顯示時間範圍選擇器
    private func showTimeRangePicker() {
        let alert = UIAlertController(
            title: NSLocalizedString("分析時間範圍", comment: ""),
            message: NSLocalizedString("選擇分析時間範圍（天）", comment: ""),
            preferredStyle: .actionSheet
        )
        
        let timeRanges = [7, 14, 30, 60, 90]
        
        for range in timeRanges {
            alert.addAction(UIAlertAction(
                title: String(format: NSLocalizedString("%d天", comment: ""), range),
                style: .default,
                handler: { [weak self] _ in
                    self?.settingsManager.updateAnalysisTimeRange(range)
                }
            ))
        }
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("取消", comment: ""),
            style: .cancel
        ))
        
        present(alert, animated: true)
    }
    
    /// 顯示自動分析頻率選擇器
    private func showAutoAnalysisFrequencyPicker() {
        let alert = UIAlertController(
            title: NSLocalizedString("自動分析頻率", comment: ""),
            message: NSLocalizedString("選擇自動分析頻率（小時）", comment: ""),
            preferredStyle: .actionSheet
        )
        
        let frequencies = [6, 12, 24, 48, 72]
        
        for frequency in frequencies {
            alert.addAction(UIAlertAction(
                title: String(format: NSLocalizedString("%d小時", comment: ""), frequency),
                style: .default,
                handler: { [weak self] _ in
                    self?.settingsManager.updateAutoAnalysisFrequency(frequency)
                }
            ))
        }
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("取消", comment: ""),
            style: .cancel
        ))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension AnalysisSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .analysisParameters:
            if let row = AnalysisParametersRow(rawValue: indexPath.row) {
                switch row {
                case .timeRange:
                    showTimeRangePicker()
                default:
                    break
                }
            }
        case .autoAnalysis:
            if let row = AutoAnalysisRow(rawValue: indexPath.row) {
                switch row {
                case .frequency:
                    showAutoAnalysisFrequencyPicker()
                default:
                    break
                }
            }
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource

extension AnalysisSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = Section(rawValue: section) else { return 0 }
        return tableSection.rowCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableSection = Section(rawValue: section) else { return nil }
        return tableSection.headerTitle
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableSection = Section(rawValue: section) else { return nil }
        return tableSection.footerTitle
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .cloudAnalysis:
            return configureCloudAnalysisCell(for: indexPath)
        case .analysisParameters:
            return configureAnalysisParametersCell(for: indexPath)
        case .autoAnalysis:
            return configureAutoAnalysisCell(for: indexPath)
        case .privacy:
            return configurePrivacyCell(for: indexPath)
        }
    }
    
    /// 配置雲端分析單元格
    private func configureCloudAnalysisCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let row = CloudAnalysisRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
        cell.textLabel?.text = row.title
        
        let switchView = UISwitch()
        
        switch row {
        case .enableCloudAnalysis:
            switchView.isOn = settings.isCloudAnalysisEnabled
            switchView.addAction(UIAction { [weak self] action in
                guard let switchView = action.sender as? UISwitch else { return }
                self?.settingsManager.updateCloudAnalysisEnabled(switchView.isOn)
            }, for: .valueChanged)
        case .onlyOnWiFi:
            switchView.isOn = settings.useCloudAnalysisOnlyOnWiFi
            switchView.isEnabled = settings.isCloudAnalysisEnabled
            switchView.addAction(UIAction { [weak self] action in
                guard let switchView = action.sender as? UISwitch else { return }
                self?.settingsManager.updateUseCloudAnalysisOnlyOnWiFi(switchView.isOn)
            }, for: .valueChanged)
        }
        
        cell.accessoryView = switchView
        return cell
    }
    
    /// 配置分析參數單元格
    private func configureAnalysisParametersCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let row = AnalysisParametersRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        
        switch row {
        case .timeRange:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ValueCell", for: indexPath)
            cell.textLabel?.text = row.title
            cell.detailTextLabel?.text = String(format: NSLocalizedString("%d天", comment: ""), settings.analysisTimeRangeDays)
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .sleepSensitivity:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell", for: indexPath)
            cell.textLabel?.text = row.title
            
            let segmentedControl = UISegmentedControl(items: AnalysisSensitivity.allCases.map { $0.localizedName })
            segmentedControl.selectedSegmentIndex = SensitivityIndex.from(sensitivity: settings.sleepAnalysisSensitivity).rawValue
            segmentedControl.addAction(UIAction { [weak self] action in
                guard let segmentedControl = action.sender as? UISegmentedControl,
                      let sensitivityIndex = SensitivityIndex(rawValue: segmentedControl.selectedSegmentIndex) else { return }
                self?.settingsManager.updateSleepAnalysisSensitivity(sensitivityIndex.sensitivity)
            }, for: .valueChanged)
            
            cell.accessoryView = segmentedControl
            return cell
            
        case .routineSensitivity:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell", for: indexPath)
            cell.textLabel?.text = row.title
            
            let segmentedControl = UISegmentedControl(items: AnalysisSensitivity.allCases.map { $0.localizedName })
            segmentedControl.selectedSegmentIndex = SensitivityIndex.from(sensitivity: settings.routineAnalysisSensitivity).rawValue
            segmentedControl.addAction(UIAction { [weak self] action in
                guard let segmentedControl = action.sender as? UISegmentedControl,
                      let sensitivityIndex = SensitivityIndex(rawValue: segmentedControl.selectedSegmentIndex) else { return }
                self?.settingsManager.updateRoutineAnalysisSensitivity(sensitivityIndex.sensitivity)
            }, for: .valueChanged)
            
            cell.accessoryView = segmentedControl
            return cell
            
        case .predictionThreshold:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath)
            cell.textLabel?.text = row.title
            
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
            
            let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 44))
            slider.minimumValue = 0.5
            slider.maximumValue = 0.9
            slider.value = Float(settings.predictionConfidenceThreshold)
            
            let valueLabel = UILabel(frame: CGRect(x: 160, y: 0, width: 40, height: 44))
            valueLabel.text = String(format: "%.0f%%", settings.predictionConfidenceThreshold * 100)
            valueLabel.font = .systemFont(ofSize: 14)
            valueLabel.textAlignment = .right
            
            slider.addAction(UIAction { action in
                guard let slider = action.sender as? UISlider else { return }
                let value = Double(slider.value)
                valueLabel.text = String(format: "%.0f%%", value * 100)
                self.settingsManager.updatePredictionConfidenceThreshold(value)
            }, for: .valueChanged)
            
            containerView.addSubview(slider)
            containerView.addSubview(valueLabel)
            
            cell.accessoryView = containerView
            return cell
        }
    }
    
    /// 配置自動分析單元格
    private func configureAutoAnalysisCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let row = AutoAnalysisRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        
        switch row {
        case .enableAutoAnalysis:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
            cell.textLabel?.text = row.title
            
            let switchView = UISwitch()
            switchView.isOn = settings.isAutoAnalysisEnabled
            switchView.addAction(UIAction { [weak self] action in
                guard let switchView = action.sender as? UISwitch else { return }
                self?.settingsManager.updateAutoAnalysisEnabled(switchView.isOn)
            }, for: .valueChanged)
            
            cell.accessoryView = switchView
            return cell
            
        case .frequency:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ValueCell", for: indexPath)
            cell.textLabel?.text = row.title
            cell.detailTextLabel?.text = String(format: NSLocalizedString("%d小時", comment: ""), settings.autoAnalysisFrequencyHours)
            cell.accessoryType = .disclosureIndicator
            cell.isUserInteractionEnabled = settings.isAutoAnalysisEnabled
            cell.textLabel?.isEnabled = settings.isAutoAnalysisEnabled
            cell.detailTextLabel?.isEnabled = settings.isAutoAnalysisEnabled
            return cell
            
        case .enableNotification:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
            cell.textLabel?.text = row.title
            
            let switchView = UISwitch()
            switchView.isOn = settings.isAnalysisNotificationEnabled
            switchView.isEnabled = settings.isAutoAnalysisEnabled
            switchView.addAction(UIAction { [weak self] action in
                guard let switchView = action.sender as? UISwitch else { return }
                self?.settingsManager.updateAnalysisNotificationEnabled(switchView.isOn)
            }, for: .valueChanged)
            
            cell.accessoryView = switchView
            return cell
        }
    }
    
    /// 配置隱私單元格
    private func configurePrivacyCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let row = PrivacyRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
        cell.textLabel?.text = row.title
        
        let switchView = UISwitch()
        
        switch row {
        case .enableAnonymization:
            switchView.isOn = settings.isDataAnonymizationEnabled
            switchView.addAction(UIAction { [weak self] action in
                guard let switchView = action.sender as? UISwitch else { return }
                self?.settingsManager.updateDataAnonymizationEnabled(switchView.isOn)
            }, for: .valueChanged)
        }
        
        cell.accessoryView = switchView
        return cell
    }
}

// MARK: - 用戶設置擴展

extension UserSettings {
    /// 分析設置
    var analysisSettings: AnalysisSettings {
        get {
            return AnalysisSettingsManager.shared.settings
        }
    }
    
    /// 是否啟用雲端分析
    var isCloudAnalysisEnabled: Bool {
        return analysisSettings.isCloudAnalysisEnabled
    }
    
    /// 是否僅在WiFi下使用雲端分析
    var useCloudAnalysisOnlyOnWiFi: Bool {
        return analysisSettings.useCloudAnalysisOnlyOnWiFi
    }
    
    /// 是否啟用數據匿名化
    var isDataAnonymizationEnabled: Bool {
        return analysisSettings.isDataAnonymizationEnabled
    }
}

// MARK: - 工廠方法

/// 創建分析設置視圖控制器
/// - Returns: 分析設置視圖控制器
func createAnalysisSettingsViewController() -> UINavigationController {
    let viewController = AnalysisSettingsViewController()
    let navigationController = UINavigationController(rootViewController: viewController)
    return navigationController
}
