import UIKit

/// 活動列表視圖控制器
class ActivitiesListViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: ActivitiesListViewModel
    
    /// 表格視圖
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        return tableView
    }()
    
    /// 活動指示器
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    /// 空狀態標籤
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "沒有活動記錄"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .gray
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter viewModel: 視圖模型
    init(viewModel: ActivitiesListViewModel) {
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
        setupBindings()
        
        // 加載數據
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 每次視圖出現時刷新數據
        loadData()
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        view.backgroundColor = .white
        
        // 設置導航欄標題
        title = "活動記錄"
        
        // 添加新增按鈕
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // 添加子視圖
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 表格視圖
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 活動指示器
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // 空狀態標籤
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    /// 設置表格視圖
    private func setupTableView() {
        // 註冊單元格
        tableView.register(ActivityCell.self, forCellReuseIdentifier: "ActivityCell")
        
        // 設置數據源和委託
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    /// 設置綁定
    private func setupBindings() {
        // 數據加載完成處理
        viewModel.onDataLoaded = { [weak self] in
            guard let self = self else { return }
            
            // 停止活動指示器
            self.activityIndicator.stopAnimating()
            
            // 刷新表格視圖
            self.tableView.reloadData()
            
            // 更新空狀態
            self.updateEmptyState()
        }
        
        // 錯誤處理
        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            
            // 停止活動指示器
            self.activityIndicator.stopAnimating()
            
            // 顯示錯誤
            self.showError(error)
        }
    }
    
    // MARK: - 數據加載
    
    /// 加載數據
    private func loadData() {
        // 顯示活動指示器
        activityIndicator.startAnimating()
        
        // 加載數據
        viewModel.loadActivities()
    }
    
    /// 更新空狀態
    private func updateEmptyState() {
        // 如果沒有活動記錄，顯示空狀態標籤
        emptyStateLabel.isHidden = !viewModel.activities.isEmpty
    }
    
    // MARK: - 動作
    
    /// 添加按鈕點擊
    @objc private func addButtonTapped() {
        // 創建活動記錄視圖控制器
        let activityRecordViewController = ActivityRecordViewController(
            viewModel: DependencyContainer.shared.resolve(ActivityRecordViewModel.self)!
        )
        
        // 顯示活動記錄視圖控制器
        navigationController?.pushViewController(activityRecordViewController, animated: true)
    }
    
    // MARK: - 輔助方法
    
    /// 顯示錯誤
    /// - Parameter error: 錯誤
    private func showError(_ error: Error) {
        // 創建警告控制器
        let alertController = UIAlertController(
            title: "錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        // 添加確定按鈕
        alertController.addAction(UIAlertAction(title: "確定", style: .default))
        
        // 顯示警告控制器
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ActivitiesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath) as? ActivityCell else {
            return UITableViewCell()
        }
        
        // 配置單元格
        let activity = viewModel.activities[indexPath.row]
        cell.configure(with: activity)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ActivitiesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 取消選中
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 獲取選中的活動
        let activity = viewModel.activities[indexPath.row]
        
        // 創建活動詳情視圖控制器
        let activityDetailViewController = ActivityDetailViewController(
            viewModel: ActivityDetailViewModel(activity: activity)
        )
        
        // 顯示活動詳情視圖控制器
        navigationController?.pushViewController(activityDetailViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 獲取要刪除的活動
            let activity = viewModel.activities[indexPath.row]
            
            // 刪除活動
            viewModel.deleteActivity(activity) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    // 刷新表格視圖
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    // 更新空狀態
                    self.updateEmptyState()
                    
                case .failure(let error):
                    // 顯示錯誤
                    self.showError(error)
                }
            }
        }
    }
}

// MARK: - ActivityCell

/// 活動單元格
class ActivityCell: UITableViewCell {
    // MARK: - 屬性
    
    /// 活動類型標籤
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 日期標籤
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 持續時間標籤
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
        contentView.addSubview(typeLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(durationLabel)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 活動類型標籤
            typeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 日期標籤
            dateLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // 持續時間標籤
            durationLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            durationLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 16),
            durationLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - 配置
    
    /// 配置單元格
    /// - Parameter activity: 活動
    func configure(with activity: Activity) {
        // 設置活動類型
        typeLabel.text = activity.type.rawValue
        
        // 設置日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateLabel.text = dateFormatter.string(from: activity.startTime)
        
        // 設置持續時間
        if let duration = activity.duration {
            let minutes = Int(duration / 60)
            durationLabel.text = "持續時間: \(minutes) 分鐘"
        } else {
            durationLabel.text = "持續時間: 未知"
        }
    }
}
