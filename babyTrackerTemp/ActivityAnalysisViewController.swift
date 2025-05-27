import UIKit

/// 活動分析視圖控制器
class ActivityAnalysisViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: ActivityAnalysisViewModel
    
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
    
    /// 日期範圍選擇器
    private let dateRangeSegmentedControl: UISegmentedControl = {
        let items = ["過去7天", "過去30天", "過去90天"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    /// 活動類型分佈圖表容器
    private let activityTypeChartContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 活動類型分佈圖表標題
    private let activityTypeChartTitle: UILabel = {
        let label = UILabel()
        label.text = "活動類型分佈"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動時間分佈圖表容器
    private let activityTimeChartContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 活動時間分佈圖表標題
    private let activityTimeChartTitle: UILabel = {
        let label = UILabel()
        label.text = "活動時間分佈"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動持續時間統計容器
    private let activityDurationContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 活動持續時間統計標題
    private let activityDurationTitle: UILabel = {
        let label = UILabel()
        label.text = "活動持續時間統計"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動持續時間統計內容
    private let activityDurationContent: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動模式分析容器
    private let activityPatternContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 活動模式分析標題
    private let activityPatternTitle: UILabel = {
        let label = UILabel()
        label.text = "活動模式分析"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動模式分析內容
    private let activityPatternContent: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    init(viewModel: ActivityAnalysisViewModel) {
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
        title = "活動分析"
        
        // 添加子視圖
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(dateRangeSegmentedControl)
        
        contentView.addSubview(activityTypeChartContainer)
        activityTypeChartContainer.addSubview(activityTypeChartTitle)
        
        contentView.addSubview(activityTimeChartContainer)
        activityTimeChartContainer.addSubview(activityTimeChartTitle)
        
        contentView.addSubview(activityDurationContainer)
        activityDurationContainer.addSubview(activityDurationTitle)
        activityDurationContainer.addSubview(activityDurationContent)
        
        contentView.addSubview(activityPatternContainer)
        activityPatternContainer.addSubview(activityPatternTitle)
        activityPatternContainer.addSubview(activityPatternContent)
        
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
            
            // 日期範圍選擇器
            dateRangeSegmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            dateRangeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateRangeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 活動類型分佈圖表容器
            activityTypeChartContainer.topAnchor.constraint(equalTo: dateRangeSegmentedControl.bottomAnchor, constant: 20),
            activityTypeChartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityTypeChartContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            activityTypeChartContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // 活動類型分佈圖表標題
            activityTypeChartTitle.topAnchor.constraint(equalTo: activityTypeChartContainer.topAnchor, constant: 16),
            activityTypeChartTitle.leadingAnchor.constraint(equalTo: activityTypeChartContainer.leadingAnchor, constant: 16),
            activityTypeChartTitle.trailingAnchor.constraint(equalTo: activityTypeChartContainer.trailingAnchor, constant: -16),
            
            // 活動時間分佈圖表容器
            activityTimeChartContainer.topAnchor.constraint(equalTo: activityTypeChartContainer.bottomAnchor, constant: 20),
            activityTimeChartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityTimeChartContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            activityTimeChartContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // 活動時間分佈圖表標題
            activityTimeChartTitle.topAnchor.constraint(equalTo: activityTimeChartContainer.topAnchor, constant: 16),
            activityTimeChartTitle.leadingAnchor.constraint(equalTo: activityTimeChartContainer.leadingAnchor, constant: 16),
            activityTimeChartTitle.trailingAnchor.constraint(equalTo: activityTimeChartContainer.trailingAnchor, constant: -16),
            
            // 活動持續時間統計容器
            activityDurationContainer.topAnchor.constraint(equalTo: activityTimeChartContainer.bottomAnchor, constant: 20),
            activityDurationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityDurationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 活動持續時間統計標題
            activityDurationTitle.topAnchor.constraint(equalTo: activityDurationContainer.topAnchor, constant: 16),
            activityDurationTitle.leadingAnchor.constraint(equalTo: activityDurationContainer.leadingAnchor, constant: 16),
            activityDurationTitle.trailingAnchor.constraint(equalTo: activityDurationContainer.trailingAnchor, constant: -16),
            
            // 活動持續時間統計內容
            activityDurationContent.topAnchor.constraint(equalTo: activityDurationTitle.bottomAnchor, constant: 8),
            activityDurationContent.leadingAnchor.constraint(equalTo: activityDurationContainer.leadingAnchor, constant: 16),
            activityDurationContent.trailingAnchor.constraint(equalTo: activityDurationContainer.trailingAnchor, constant: -16),
            activityDurationContent.bottomAnchor.constraint(equalTo: activityDurationContainer.bottomAnchor, constant: -16),
            
            // 活動模式分析容器
            activityPatternContainer.topAnchor.constraint(equalTo: activityDurationContainer.bottomAnchor, constant: 20),
            activityPatternContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityPatternContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 活動模式分析標題
            activityPatternTitle.topAnchor.constraint(equalTo: activityPatternContainer.topAnchor, constant: 16),
            activityPatternTitle.leadingAnchor.constraint(equalTo: activityPatternContainer.leadingAnchor, constant: 16),
            activityPatternTitle.trailingAnchor.constraint(equalTo: activityPatternContainer.trailingAnchor, constant: -16),
            
            // 活動模式分析內容
            activityPatternContent.topAnchor.constraint(equalTo: activityPatternTitle.bottomAnchor, constant: 8),
            activityPatternContent.leadingAnchor.constraint(equalTo: activityPatternContainer.leadingAnchor, constant: 16),
            activityPatternContent.trailingAnchor.constraint(equalTo: activityPatternContainer.trailingAnchor, constant: -16),
            activityPatternContent.bottomAnchor.constraint(equalTo: activityPatternContainer.bottomAnchor, constant: -16),
            activityPatternContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // 活動指示器
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 添加日期範圍選擇器動作
        dateRangeSegmentedControl.addTarget(self, action: #selector(dateRangeChanged), for: .valueChanged)
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
        
        // 獲取選擇的日期範圍
        let dateRange = getSelectedDateRange()
        
        // 加載數據
        viewModel.loadData(from: dateRange.startDate, to: dateRange.endDate)
    }
    
    /// 更新UI
    private func updateUI() {
        // 更新活動持續時間統計
        activityDurationContent.text = viewModel.activityDurationSummary
        
        // 更新活動模式分析
        activityPatternContent.text = viewModel.activityPatternSummary
        
        // 更新圖表
        updateCharts()
    }
    
    /// 更新圖表
    private func updateCharts() {
        // 在實際應用中，這裡會使用圖表庫（如Charts）來繪製圖表
        // 由於這是示例代碼，我們只添加一個簡單的標籤來模擬圖表
        
        // 移除舊的圖表
        activityTypeChartContainer.subviews.forEach { subview in
            if subview != activityTypeChartTitle {
                subview.removeFromSuperview()
            }
        }
        
        activityTimeChartContainer.subviews.forEach { subview in
            if subview != activityTimeChartTitle {
                subview.removeFromSuperview()
            }
        }
        
        // 添加活動類型分佈圖表
        let typeChartLabel = UILabel()
        typeChartLabel.text = "此處將顯示活動類型分佈圖表"
        typeChartLabel.textAlignment = .center
        typeChartLabel.textColor = .gray
        typeChartLabel.translatesAutoresizingMaskIntoConstraints = false
        activityTypeChartContainer.addSubview(typeChartLabel)
        
        NSLayoutConstraint.activate([
            typeChartLabel.centerXAnchor.constraint(equalTo: activityTypeChartContainer.centerXAnchor),
            typeChartLabel.centerYAnchor.constraint(equalTo: activityTypeChartContainer.centerYAnchor)
        ])
        
        // 添加活動時間分佈圖表
        let timeChartLabel = UILabel()
        timeChartLabel.text = "此處將顯示活動時間分佈圖表"
        timeChartLabel.textAlignment = .center
        timeChartLabel.textColor = .gray
        timeChartLabel.translatesAutoresizingMaskIntoConstraints = false
        activityTimeChartContainer.addSubview(timeChartLabel)
        
        NSLayoutConstraint.activate([
            timeChartLabel.centerXAnchor.constraint(equalTo: activityTimeChartContainer.centerXAnchor),
            timeChartLabel.centerYAnchor.constraint(equalTo: activityTimeChartContainer.centerYAnchor)
        ])
    }
    
    // MARK: - 動作
    
    /// 日期範圍變更
    @objc private func dateRangeChanged() {
        // 加載數據
        loadData()
    }
    
    // MARK: - 輔助方法
    
    /// 獲取選擇的日期範圍
    /// - Returns: 開始日期和結束日期
    private func getSelectedDateRange() -> (startDate: Date, endDate: Date) {
        let endDate = Date()
        var startDate: Date
        
        switch dat
(Content truncated due to size limit. Use line ranges to read in chunks)