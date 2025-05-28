import UIKit

/// 活動詳情視圖控制器
class ActivityDetailViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: ActivityDetailViewModel
    
    /// 活動類型標籤
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 開始時間標籤
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 結束時間標籤
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 持續時間標籤
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 備註標籤
    private let notesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 編輯按鈕
    private lazy var editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("編輯", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        return button
    }()
    
    /// 刪除按鈕
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("刪除", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter viewModel: 視圖模型
    init(viewModel: ActivityDetailViewModel) {
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
        updateUI()
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        view.backgroundColor = .white
        
        // 設置導航欄標題
        title = "活動詳情"
        
        // 添加子視圖
        view.addSubview(typeLabel)
        view.addSubview(startTimeLabel)
        view.addSubview(endTimeLabel)
        view.addSubview(durationLabel)
        view.addSubview(notesLabel)
        view.addSubview(editButton)
        view.addSubview(deleteButton)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 活動類型標籤
            typeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            typeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            typeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 開始時間標籤
            startTimeLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 16),
            startTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 結束時間標籤
            endTimeLabel.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 12),
            endTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            endTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 持續時間標籤
            durationLabel.topAnchor.constraint(equalTo: endTimeLabel.bottomAnchor, constant: 12),
            durationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 備註標籤
            notesLabel.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 16),
            notesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            notesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 編輯按鈕
            editButton.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 32),
            editButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            editButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            editButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 刪除按鈕
            deleteButton.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 32),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deleteButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            deleteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    /// 更新UI
    private func updateUI() {
        // 獲取活動
        let activity = viewModel.activity
        
        // 更新活動類型
        typeLabel.text = "活動類型：\(activity.type.rawValue)"
        
        // 更新開始時間
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        startTimeLabel.text = "開始時間：\(dateFormatter.string(from: activity.startTime))"
        
        // 更新結束時間
        if let endTime = activity.endTime {
            endTimeLabel.text = "結束時間：\(dateFormatter.string(from: endTime))"
        } else {
            endTimeLabel.text = "結束時間：未記錄"
        }
        
        // 更新持續時間
        if let duration = activity.duration {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            let seconds = Int(duration) % 60
            
            if hours > 0 {
                durationLabel.text = "持續時間：\(hours)小時 \(minutes)分鐘 \(seconds)秒"
            } else {
                durationLabel.text = "持續時間：\(minutes)分鐘 \(seconds)秒"
            }
        } else {
            durationLabel.text = "持續時間：未記錄"
        }
        
        // 更新備註
        if let notes = activity.notes, !notes.isEmpty {
            notesLabel.text = "備註：\(notes)"
        } else {
            notesLabel.text = "備註：無"
        }
    }
    
    // MARK: - 動作
    
    /// 編輯按鈕點擊
    @objc private func editButtonTapped() {
        // 創建活動記錄視圖控制器
        let activityRecordViewModel = ActivityRecordViewModel(
            activityRepository: DependencyContainer.shared.resolve(ActivityRepository.self)!,
            activity: viewModel.activity
        )
        let activityRecordViewController = ActivityRecordViewController(viewModel: activityRecordViewModel)
        
        // 顯示活動記錄視圖控制器
        navigationController?.pushViewController(activityRecordViewController, animated: true)
    }
    
    /// 刪除按鈕點擊
    @objc private func deleteButtonTapped() {
        // 創建警告控制器
        let alertController = UIAlertController(
            title: "確認刪除",
            message: "確定要刪除這條活動記錄嗎？",
            preferredStyle: .alert
        )
        
        // 添加取消按鈕
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 添加確定按鈕
        alertController.addAction(UIAlertAction(title: "確定", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // 刪除活動
            self.viewModel.deleteActivity { result in
                switch result {
                case .success:
                    // 返回上一個視圖控制器
                    self.navigationController?.popViewController(animated: true)
                    
                case .failure(let error):
                    // 顯示錯誤
                    self.showError(error)
                }
            }
        })
        
        // 顯示警告控制器
        present(alertController, animated: true)
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
