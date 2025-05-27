import UIKit

/// 餵食分析視圖控制器
class FeedingAnalysisViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: FeedingAnalysisViewModel
    
    /// 餵食類型標籤
    private let feedingTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 平均餵食時間標籤
    private let averageFeedingTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 餵食間隔標籤
    private let feedingIntervalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 餵食模式標籤
    private let feedingPatternLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 分析結果標籤
    private let analysisResultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 深度分析按鈕
    private lazy var deepAnalysisButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("深度分析", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deepAnalysisButtonTapped), for: .touchUpInside)
        return button
    }()
    
    /// 活動指示器
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter viewModel: 視圖模型
    init(viewModel: FeedingAnalysisViewModel) {
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
        setupBindings()
        
        // 加載數據
        viewModel.loadData()
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        view.backgroundColor = .white
        
        // 設置導航欄標題
        title = "餵食分析"
        
        // 添加子視圖
        view.addSubview(feedingTypeLabel)
        view.addSubview(averageFeedingTimeLabel)
        view.addSubview(feedingIntervalLabel)
        view.addSubview(feedingPatternLabel)
        view.addSubview(analysisResultLabel)
        view.addSubview(deepAnalysisButton)
        view.addSubview(activityIndicator)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 餵食類型標籤
            feedingTypeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            feedingTypeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            feedingTypeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 平均餵食時間標籤
            averageFeedingTimeLabel.topAnchor.constraint(equalTo: feedingTypeLabel.bottomAnchor, constant: 16),
            averageFeedingTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            averageFeedingTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 餵食間隔標籤
            feedingIntervalLabel.topAnchor.constraint(equalTo: averageFeedingTimeLabel.bottomAnchor, constant: 16),
            feedingIntervalLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            feedingIntervalLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 餵食模式標籤
            feedingPatternLabel.topAnchor.constraint(equalTo: feedingIntervalLabel.bottomAnchor, constant: 16),
            feedingPatternLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            feedingPatternLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 分析結果標籤
            analysisResultLabel.topAnchor.constraint(equalTo: feedingPatternLabel.bottomAnchor, constant: 24),
            analysisResultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            analysisResultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 深度分析按鈕
            deepAnalysisButton.topAnchor.constraint(equalTo: analysisResultLabel.bottomAnchor, constant: 32),
            deepAnalysisButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deepAnalysisButton.widthAnchor.constraint(equalToConstant: 200),
            deepAnalysisButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 活動指示器
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: deepAnalysisButton.bottomAnchor, constant: 20)
        ])
    }
    
    /// 設置綁定
    private func setupBindings() {
        // 數據加載完成處理
        viewModel.onDataLoaded = { [weak self] in
            guard let self = self else { return }
            
            // 更新UI
            self.updateUI()
        }
        
        // 分析完成處理
        viewModel.onAnalysisCompleted = { [weak self] result in
            guard let self = self else { return }
            
            // 停止活動指示器
            self.activityIndicator.stopAnimating()
            
            // 啟用深度分析按鈕
            self.deepAnalysisButton.isEnabled = true
            
            // 處理結果
            switch result {
            case .success(let analysisResult):
                // 顯示分析結果
                self.analysisResultLabel.text = "分析結果：\(analysisResult)"
                
            case .failure(let error):
                // 顯示錯誤
                self.showError(error)
            }
        }
    }
    
    /// 更新UI
    private func updateUI() {
        // 更新餵食類型
        if let feedingType = viewModel.dominantFeedingType {
            feedingTypeLabel.text = "主要餵食類型：\(feedingType)"
        } else {
            feedingTypeLabel.text = "主要餵食類型：無數據"
        }
        
        // 更新平均餵食時間
        if let averageDuration = viewModel.averageFeedingDuration {
            let minutes = Int(averageDuration / 60)
            let seconds = Int(averageDuration.truncatingRemainder(dividingBy: 60))
            averageFeedingTimeLabel.text = "平均餵食時間：\(minutes)分\(seconds)秒"
        } else {
            averageFeedingTimeLabel.text = "平均餵食時間：無數據"
        }
        
        // 更新餵食間隔
        if let interval = viewModel.averageFeedingInterval {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            feedingIntervalLabel.text = "平均餵食間隔：\(hours)小時\(minutes)分鐘"
        } else {
            feedingIntervalLabel.text = "平均餵食間隔：無數據"
        }
        
        // 更新餵食模式
        if let pattern = viewModel.feedingPattern {
            feedingPatternLabel.text = "餵食模式：\(pattern)"
        } else {
            feedingPatternLabel.text = "餵食模式：無數據"
        }
        
        // 更新分析結果
        if let analysis = viewModel.analysis {
            analysisResultLabel.text = "分析結果：\(analysis)"
        } else {
            analysisResultLabel.text = "分析結果：尚未進行深度分析"
        }
    }
    
    // MARK: - 動作
    
    /// 深度分析按鈕點擊
    @objc private func deepAnalysisButtonTapped() {
        // 禁用按鈕
        deepAnalysisButton.isEnabled = false
        
        // 顯示活動指示器
        activityIndicator.startAnimating()
        
        // 執行深度分析
        viewModel.performDeepAnalysis()
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
