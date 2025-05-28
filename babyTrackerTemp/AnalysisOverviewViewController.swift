import UIKit

/// 分析總覽視圖控制器
class AnalysisOverviewViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: AnalysisOverviewViewModel
    
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
    
    /// 睡眠分析卡片
    private lazy var sleepAnalysisCard: AnalysisCardView = {
        let card = AnalysisCardView(title: "睡眠分析", iconName: "bed.double.fill")
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sleepAnalysisCardTapped)))
        return card
    }()
    
    /// 餵食分析卡片
    private lazy var feedingAnalysisCard: AnalysisCardView = {
        let card = AnalysisCardView(title: "餵食分析", iconName: "drop.fill")
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(feedingAnalysisCardTapped)))
        return card
    }()
    
    /// 活動分析卡片
    private lazy var activityAnalysisCard: AnalysisCardView = {
        let card = AnalysisCardView(title: "活動分析", iconName: "figure.walk")
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activityAnalysisCardTapped)))
        return card
    }()
    
    /// 成長分析卡片
    private lazy var growthAnalysisCard: AnalysisCardView = {
        let card = AnalysisCardView(title: "成長分析", iconName: "chart.line.uptrend.xyaxis")
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(growthAnalysisCardTapped)))
        return card
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
    init(viewModel: AnalysisOverviewViewModel) {
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
        loadData()
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        view.backgroundColor = .white
        
        // 設置導航欄標題
        title = "分析"
        
        // 添加子視圖
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(sleepAnalysisCard)
        contentView.addSubview(feedingAnalysisCard)
        contentView.addSubview(activityAnalysisCard)
        contentView.addSubview(growthAnalysisCard)
        view.addSubview(activityIndicator)
        
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
            
            // 睡眠分析卡片
            sleepAnalysisCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            sleepAnalysisCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sleepAnalysisCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sleepAnalysisCard.heightAnchor.constraint(equalToConstant: 120),
            
            // 餵食分析卡片
            feedingAnalysisCard.topAnchor.constraint(equalTo: sleepAnalysisCard.bottomAnchor, constant: 20),
            feedingAnalysisCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            feedingAnalysisCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            feedingAnalysisCard.heightAnchor.constraint(equalToConstant: 120),
            
            // 活動分析卡片
            activityAnalysisCard.topAnchor.constraint(equalTo: feedingAnalysisCard.bottomAnchor, constant: 20),
            activityAnalysisCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityAnalysisCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            activityAnalysisCard.heightAnchor.constraint(equalToConstant: 120),
            
            // 成長分析卡片
            growthAnalysisCard.topAnchor.constraint(equalTo: activityAnalysisCard.bottomAnchor, constant: 20),
            growthAnalysisCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            growthAnalysisCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            growthAnalysisCard.heightAnchor.constraint(equalToConstant: 120),
            growthAnalysisCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // 活動指示器
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    /// 設置綁定
    private func setupBindings() {
        // 數據加載完成處理
        viewModel.onDataLoaded = { [weak self] in
            guard let self = self else { return }
            
            // 停止活動指示器
            self.activityIndicator.stopAnimating()
            
            // 更新UI
            self.updateUI()
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
        viewModel.loadData()
    }
    
    /// 更新UI
    private func updateUI() {
        // 更新睡眠分析卡片
        sleepAnalysisCard.updateSummary(viewModel.sleepAnalysisSummary)
        
        // 更新餵食分析卡片
        feedingAnalysisCard.updateSummary(viewModel.feedingAnalysisSummary)
        
        // 更新活動分析卡片
        activityAnalysisCard.updateSummary(viewModel.activityAnalysisSummary)
        
        // 更新成長分析卡片
        growthAnalysisCard.updateSummary(viewModel.growthAnalysisSummary)
    }
    
    // MARK: - 動作
    
    /// 睡眠分析卡片點擊
    @objc private func sleepAnalysisCardTapped() {
        // 創建睡眠儀表板視圖控制器
        let sleepDashboardViewController = SleepDashboardViewController(
            viewModel: DependencyContainer.shared.resolve(SleepDashboardViewModel.self)!
        )
        
        // 顯示睡眠儀表板視圖控制器
        navigationController?.pushViewController(sleepDashboardViewController, animated: true)
    }
    
    /// 餵食分析卡片點擊
    @objc private func feedingAnalysisCardTapped() {
        // 創建餵食分析視圖控制器
        let feedingAnalysisViewController = FeedingAnalysisViewController(
            viewModel: DependencyContainer.shared.resolve(FeedingAnalysisViewModel.self)!
        )
        
        // 顯示餵食分析視圖控制器
        navigationController?.pushViewController(feedingAnalysisViewController, animated: true)
    }
    
    /// 活動分析卡片點擊
    @objc private func activityAnalysisCardTapped() {
        // 創建活動分析視圖控制器
        let activityAnalysisViewController = ActivityAnalysisViewController(
            viewModel: DependencyContainer.shared.resolve(ActivityAnalysisViewModel.self)!
        )
        
        // 顯示活動分析視圖控制器
        navigationController?.pushViewController(activityAnalysisViewController, animated: true)
    }
    
    /// 成長分析卡片點擊
    @objc private func growthAnalysisCardTapped() {
        // 創建成長分析視圖控制器
        let growthAnalysisViewController = GrowthAnalysisViewController(
            viewModel: DependencyContainer.shared.resolve(GrowthAnalysisViewModel.self)!
        )
        
        // 顯示成長分析視圖控制器
        navigationController?.pushViewController(growthAnalysisViewController, animated: true)
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

// MARK: - AnalysisCardView

/// 分析卡片視圖
class AnalysisCardView: UIView {
    // MARK: - 屬性
    
    /// 標題標籤
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 圖標圖像視圖
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// 摘要標籤
    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 箭頭圖像視圖
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - title: 標題
    ///   - iconName: 圖標名稱
    init(title: String, iconName: String) {
        super.init(frame: .zero)
        
        // 設置標題
        titleLabel.text = title
        
        // 設置圖標
        iconImageView.image = UIImage(systemName: iconName)
        
        // 設置UI
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        backgroundColor = .white
        
        // 設置圓角
        layer.cornerRadius = 12
        
        // 設置陰影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        // 添加子視圖
        addSubview(titleLabel)
        addSubview(iconImageView)
        addSubview(summaryLabel)
        addSubview(arrowImageView)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 圖標圖像視圖
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // 標題標籤
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -16),
            
            // 摘要標籤
            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -16),
            summaryLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            
            // 箭頭圖像視圖
            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - 公共方法
    
    /// 更新摘要
    /// - Parameter summary: 摘要
    func updateSummary(_ summary: String?) {
        summaryLabel.text = summary ?? "暫無數據"
    }
}
