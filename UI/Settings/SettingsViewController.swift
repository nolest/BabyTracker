import UIKit

/// 設置視圖控制器
class SettingsViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: SettingsViewModel
    
    /// 表格視圖
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        return tableView
    }()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter viewModel: 視圖模型
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        view.backgroundColor = .systemGroupedBackground
        
        // 設置導航欄標題
        title = "設置"
        
        // 添加子視圖
        view.addSubview(tableView)
        
        // 設置約束
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    /// 設置表格視圖
    private func setupTableView() {
        // 註冊單元格
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        
        // 設置數據源和委託
        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.sections[indexPath.section].items[indexPath.row]
        
        switch item.type {
        case .toggle(let isOn):
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            cell.configure(title: item.title, isOn: isOn) { [weak self] isOn in
                self?.viewModel.toggleSetting(at: indexPath, isOn: isOn)
            }
            return cell
            
        case .navigation:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
            cell.textLabel?.text = item.title
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .info(let detail):
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = detail
            return cell
            
        case .action:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
            cell.textLabel?.text = item.title
            cell.textLabel?.textColor = .systemBlue
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footer
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = viewModel.sections[indexPath.section].items[indexPath.row]
        
        switch item.type {
        case .navigation:
            handleNavigation(for: item, at: indexPath)
            
        case .action:
            handleAction(for: item, at: indexPath)
            
        default:
            break
        }
    }
    
    /// 處理導航
    /// - Parameters:
    ///   - item: 設置項
    ///   - indexPath: 索引路徑
    private func handleNavigation(for item: SettingsItem, at indexPath: IndexPath) {
        switch item.identifier {
        case "babyProfile":
            let babyProfileViewController = BabyProfileViewController(
                viewModel: DependencyContainer.shared.resolve(BabyProfileViewModel.self)!
            )
            navigationController?.pushViewController(babyProfileViewController, animated: true)
            
        case "notifications":
            let notificationSettingsViewController = NotificationSettingsViewController(
                viewModel: DependencyContainer.shared.resolve(NotificationSettingsViewModel.self)!
            )
            navigationController?.pushViewController(notificationSettingsViewController, animated: true)
            
        case "aiSettings":
            let aiSettingsViewController = AISettingsViewController(
                viewModel: DependencyContainer.shared.resolve(AISettingsViewModel.self)!
            )
            navigationController?.pushViewController(aiSettingsViewController, animated: true)
            
        case "dataManagement":
            let dataManagementViewController = DataManagementViewController(
                viewModel: DependencyContainer.shared.resolve(DataManagementViewModel.self)!
            )
            navigationController?.pushViewController(dataManagementViewController, animated: true)
            
        case "about":
            let aboutViewController = AboutViewController()
            navigationController?.pushViewController(aboutViewController, animated: true)
            
        default:
            break
        }
    }
    
    /// 處理動作
    /// - Parameters:
    ///   - item: 設置項
    ///   - indexPath: 索引路徑
    private func handleAction(for item: SettingsItem, at indexPath: IndexPath) {
        switch item.identifier {
        case "feedback":
            // 處理反饋
            if let url = URL(string: "mailto:support@babytracker.app") {
                UIApplication.shared.open(url)
            }
            
        case "rateApp":
            // 處理評分
            if let url = URL(string: "itms-apps://itunes.apple.com/app/idXXXXXXXXXX?action=write-review") {
                UIApplication.shared.open(url)
            }
            
        case "shareApp":
            // 處理分享
            let activityViewController = UIActivityViewController(
                activityItems: ["推薦給你一款寶寶生活記錄應用：寶寶生活記錄專業版", URL(string: "https://apps.apple.com/app/idXXXXXXXXXX")!],
                applicationActivities: nil
            )
            present(activityViewController, animated: true)
            
        default:
            break
        }
    }
}

// MARK: - SwitchTableViewCell

/// 開關表格視圖單元格
class SwitchTableViewCell: UITableViewCell {
    // MARK: - 屬性
    
    /// 開關
    private let switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    /// 值變更回調
    private var valueChanged: ((Bool) -> Void)?
    
    // MARK: - 初始化
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 添加子視圖
        contentView.addSubview(switchControl)
        
        // 設置約束
        NSLayoutConstraint.activate([
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        // 添加動作
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }
    
    // MARK: - 配置
    
    /// 配置單元格
    /// - Parameters:
    ///   - title: 標題
    ///   - isOn: 是否開啟
    ///   - valueChanged: 值變更回調
    func configure(title: String, isOn: Bool, valueChanged: @escaping (Bool) -> Void) {
        textLabel?.text = title
        switchControl.isOn = isOn
        self.valueChanged = valueChanged
    }
    
    // MARK: - 動作
    
    /// 開關值變更
    @objc private func switchValueChanged() {
        valueChanged?(switchControl.isOn)
    }
}
