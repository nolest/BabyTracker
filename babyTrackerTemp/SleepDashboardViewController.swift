import UIKit

/// 睡眠儀表板視圖控制器
class SleepDashboardViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: SleepDashboardViewModel
    
    /// 滾動視圖
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    /// 內容視圖
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 總覽卡片視圖
    private let overviewCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 總覽標題標籤
    private let overviewTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "睡眠總覽"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 平均睡眠時間標籤
    private let averageSleepLabel: UILabel = {
        let label = UILabel()
        label.text = "平均睡眠時間: 加載中..."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 睡眠質量標籤
    private let sleepQualityLabel: UILabel = {
        let label = UILabel()
        label.text = "睡眠質量: 加載中..."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 睡眠模式標籤
    private let sleepPatternLabel: UILabel = {
        let label = UILabel()
        label.text = "睡眠模式: 加載中..."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 圖表容器視圖
    private let chartContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 圖表標題標籤
    private let chartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "睡眠趨勢"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 圖表視圖
    private let chartView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 分析卡片視圖
    private let analysisCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 分析標題標籤
    private let analysisTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI 分析"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 分析內容標籤
    private let analysisContentLabel: UILabel = {
        let label = UILabel()
        label.text = "加載中..."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 分析按鈕
    private let analyzeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("深度分析", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
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
    init(viewModel: SleepDashboardViewModel = SleepDashboardViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設置視圖
        setupView()
        
        // 設置導航欄
        setupNavigationBar()
        
        // 綁定視圖模型
        bindViewModel()
        
        // 設置動作
        setupActions()
        
        // 加載數據
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 刷新數據
        refreshData()
    }
    
    // MARK: - 私有方法
    
    /// 設置視圖
    private func setupView() {
        // 設置背景色
        view.backgroundColor = .systemGroupedBackground
        
        // 添加滾動視圖
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 添加卡片視圖
        contentView.addSubview(overviewCardView)
        contentView.addSubview(chartContainerView)
        contentView.addSubview(analysisCardView)
        
        // 添加總覽卡片內容
        overviewCardView.addSubview(overviewTitleLabel)
        overviewCardView.addSubview(averageSleepLabel)
        overviewCardView.addSubview(sleepQualityLabel)
        overviewCardView.addSubview(sleepPatternLabel)
        
        // 添加圖表卡片內容
        chartContainerView.addSubview(chartTitleLabel)
        chartContainerView.addSubview(chartView)
        
        // 添加分析卡片內容
        analysisCardView.addSubview(analysisTitleLabel)
        analysisCardView.addSubview(analysisContentLabel)
        analysisCardView.addSubview(analyzeButton)
        analysisCardView.addSubview(activityIndicator)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 滾動視圖
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 內容視圖
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 總覽卡片視圖
            overviewCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            overviewCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            overviewCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 總覽標題標籤
            overviewTitleLabel.topAnchor.constraint(equalTo: overviewCardView.topAnchor, constant: 16),
            overviewTitleLabel.leadingAnchor.constraint(equalTo: overviewCardView.leadingAnchor, constant: 16),
            overviewTitleLabel.trailingAnchor.constraint(equalTo: overviewCardView.trailingAnchor, constant: -16),
            
            // 平均睡眠時間標籤
            averageSleepLabel.topAnchor.constraint(equalTo: overviewTitleLabel.bottomAnchor, constant: 16),
            averageSleepLabel.leadingAnchor.constraint(equalTo: overviewCardView.leadingAnchor, constant: 16),
            averageSleepLabel.trailingAnchor.constraint(equalTo: overviewCardView.trailingAnchor, constant: -16),
            
            // 睡眠質量標籤
            sleepQualityLabel.topAnchor.constraint(equalTo: averageSleepLabel.bottomAnchor, constant: 8),
            sleepQualityLabel.leadingAnchor.constraint(equalTo: overviewCardView.leadingAnchor, constant: 16),
            sleepQualityLabel.trailingAnchor.constraint(equalTo: overviewCardView.trailingAnchor, constant: -16),
            
            // 睡眠模式標籤
            sleepPatternLabel.topAnchor.constraint(equalTo: sleepQualityLabel.bottomAnchor, constant: 8),
            sleepPatternLabel.leadingAnchor.constraint(equalTo: overviewCardView.leadingAnchor, constant: 16),
            sleepPatternLabel.trailingAnchor.constraint(equalTo: overviewCardView.trailingAnchor, constant: -16),
            sleepPatternLabel.bottomAnchor.constraint(equalTo: overviewCardView.bottomAnchor, constant: -16),
            
            // 圖表容器視圖
            chartContainerView.topAnchor.constraint(equalTo: overviewCardView.bottomAnchor, constant: 16),
            chartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 圖表標題標籤
            chartTitleLabel.topAnchor.constraint(equalTo: chartContainerView.topAnchor, constant: 16),
            chartTitleLabel.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor, constant: 16),
            chartTitleLabel.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor, constant: -16),
            
            // 圖表視圖
            chartView.topAnchor.constraint(equalTo: chartTitleLabel.bottomAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 200),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: -16),
            
            // 分析卡片視圖
            analysisCardView.topAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 16),
            analysisCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            analysisCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            analysisCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // 分析標題標籤
            analysisTitleLabel.topAnchor.constraint(equalTo: analysisCardView.topAnchor, constant: 16),
            analysisTitleLabel.leadingAnchor.constraint(equalTo: analysisCardView.leadingAnchor, constant: 16),
            analysisTitleLabel.trailingAnchor.constraint(equalTo: analysisCardView.trailingAnchor, constant: -16),
            
            // 分析內容標籤
            analysisContentLabel.topAnchor.constraint(equalTo: analysisTitleLabel.bottomAnchor, constant: 16),
            analysisContentLabel.leadingAnchor.constraint(equalTo: analysisCardView.leadingAnchor, constant: 16),
            analysisContentLabel.trailingAnchor.constraint(equalTo: analysisCardView.trailingAnchor, constant: -16),
            
            // 分析按鈕
            analyzeButton.topAnchor.constraint(equalTo: analysisContentLabel.bottomAnchor, constant: 16),
            analyzeButton.leadingAnchor.constraint(equalTo: analysisCardView.leadingAnchor, constant: 16),
            analyzeButton.trailingAnchor.constraint(equalTo: analysisCardView.trailingAnchor, constant: -16),
            analyzeButton.heightAnchor.constraint(equalToConstant: 44),
            analyzeButton.bottomAnchor.constraint(equalTo: analysisCardView.bottomAnchor, constant: -16),
            
            // 活動指示器
            activityIndicator.centerXAnchor.constraint(equalTo: analyzeButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: analyzeButton.centerYAnchor)
        ])
    }
    
    /// 設置導航欄
    private func setupNavigationBar() {
        // 設置標題
        navigationItem.title = "睡眠儀表板"
        
        // 設置刷新按鈕
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonTapped))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    /// 綁定視圖模型
    private func bindViewModel() {
        // 綁定數據加載完成
        viewModel.onDataLoaded = { [weak self] in
            guard let self = self else { return }
            
            // 更新UI
            self.updateUI()
        }
        
        // 綁定分析完成
        viewModel.onAnalysisCompleted = { [weak self] result in
            guard let self = self else { return }
            
            // 停止活動指示器
            self.activityIndicator.stopAnimating()
            
            // 啟用分析按鈕
            self.analyzeButton.isEnabled = true
            
            switch result {
            case .success(let analysis):
                // 更新分析內容
                self.analysisContentLabel.text = analysis
                
            case .failure(let error):
                // 顯示錯誤提示
                self.analysisContentLabel.text = "分析失敗: \(error.localizedDescription)"
                
                // 檢查是否為網絡錯誤
                if let networkError = error as? NetworkError, networkError == .noConnection {
                    // 顯示離線模式提示
                    let alert = UIAlertController(title: "離線模式", message: "您目前處於離線模式，無法使用雲端AI分析功能。請檢查網絡連接後重試。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "確定", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    /// 設置動作
    private func setupActions() {
        // 分析按鈕
        analyzeButton.addTarget(self, action: #selector(analyzeButtonTapped), for: .touchUpInside)
    }
    
    /// 加載數據
    private func loadData() {
        // 顯示加載中
        averageSleepLabel.text = "平均睡眠時間: 加載中..."
        sleepQualityLabel.text = "睡眠質量: 加載中..."
        sleepPatternLabel.text = "睡眠模式: 加載中..."
        analysisContentLabel.text = "加載中..."
        
        // 加載數據
        viewModel.loadData()
    }
    
    /// 刷新數據
    private func refreshData() {
        // 加載數據
        viewModel.loadData()
    }
    
    /// 更新UI
    private func updateUI() {
        // 更新平均睡眠時間
        if let averageSleepDuration = viewModel.averageSleepDuration {
            let hours = Int(averageSleepDuration / 3600)
            let minutes = Int((averageSleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
            averageSleepLabel.text = "平均睡眠時間: \(hours)小時\(minutes)分鐘"
        } else {
            averageSleepLabel.text = "平均睡眠時間: 無數據"
        }
        
        // 更新睡眠質量
        if let sleepQuality = viewModel.sleepQuality {
            sleepQualityLabel.text = "睡眠質量: \(sleepQuality)"
        } else {
       
(Content truncated due to size limit. Use line ranges to read in chunks)