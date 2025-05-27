import UIKit

/// 首頁視圖控制器
class HomeViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: HomeViewModel
    
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
    
    /// 寶寶信息視圖
    private let babyInfoView: UIView = {
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
    
    /// 寶寶頭像
    private let babyAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.backgroundColor = .systemGray5
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// 寶寶名稱標籤
    private let babyNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 寶寶年齡標籤
    private let babyAgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 最近活動標籤
    private let recentActivitiesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.text = "最近活動"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 最近活動表格視圖
    private let recentActivitiesTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    /// 快速操作標籤
    private let quickActionsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.text = "快速操作"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 快速操作集合視圖
    private let quickActionsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    /// 今日摘要標籤
    private let todaySummaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.text = "今日摘要"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 今日摘要視圖
    private let todaySummaryView: UIView = {
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
    
    /// 睡眠時間標籤
    private let sleepTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = "睡眠時間"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 睡眠時間值標籤
    private let sleepTimeValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 餵食次數標籤
    private let feedingCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = "餵食次數"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 餵食次數值標籤
    private let feedingCountValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 尿布次數標籤
    private let diaperCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = "尿布次數"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 尿布次數值標籤
    private let diaperCountValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動次數標籤
    private let activityCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = "活動次數"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動次數值標籤
    private let activityCountValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// AI分析標籤
    private let aiAnalysisLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.text = "AI分析"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// AI分析視圖
    private let aiAnalysisView: UIView = {
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
    
    /// AI分析內容標籤
    private let aiAnalysisContentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 刷新控制
    private let refreshControl = UIRefreshControl()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter viewModel: 視圖模型
    init(viewModel: HomeViewModel) {
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
        
        // 設置表格視圖
        setupTableView()
        
        // 設置集合視圖
        setupCollectionView()
        
        // 設置刷新控制
        setupRefreshControl()
        
        // 綁定視圖模型
        bindViewModel()
        
        // 加載數據
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 刷新數據
        loadData()
    }
    
    // MARK: - 私有方法
    
    /// 設置視圖
    private func setupView() {
        // 設置背景色
        view.backgroundColor = .systemGroupedBackground
        
        // 添加滾動視圖
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 添加子視圖
        contentView.addSubview(babyInfoView)
        babyInfoView.addSubview(babyAvatarImageView)
        babyInfoView.addSubview(babyNameLabel)
        babyInfoView.addSubview(babyAgeLabel)
        
        contentView.addSubview(recentActivitiesLabel)
        contentView.addSubview(recentActivitiesTableView)
        
        contentView.addSubview(quickActionsLabel)
        contentView.addSubview(quickActionsCollectionView)
        
        contentView.addSubview(todaySummaryLabel)
        contentView.addSubview(todaySummaryView)
        todaySummaryView.addSubview(sleepTimeLabel)
        todaySummaryView.addSubview(sleepTimeValueLabel)
        todaySummaryView.addSubview(feedingCountLabel)
        todaySummaryView.addSubview(feedingCountValueLabel)
        todaySummaryView.addSubview(diaperCountLabel)
        todaySummaryView.addSubview(diaperCountValueLabel)
        todaySummaryView.addSubview(activityCountLabel)
        todaySummaryView.addSubview(activityCountValueLabel)
        
        contentView.addSubview(aiAnalysisLabel)
        contentView.addSubview(aiAnalysisView)
        aiAnalysisView.addSubview(aiAnalysisContentLabel)
        
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
            
            // 寶寶信息視圖
            babyInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            babyInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            babyInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            babyInfoView.heightAnchor.constraint(equalToConstant: 80),
            
            // 寶寶頭像
            babyAvatarImageView.leadingAnchor.constraint(equalTo: babyInfoView.leadingAnchor, constant: 16),
            babyAvatarImageView.centerYAnchor.constraint(equalTo: babyInfoView.centerYAnchor),
            babyAvatarImageView.widthAnchor.constraint(equalToConstant: 60),
            babyAvatarImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // 寶寶名稱標籤
            babyNameLabel.topAnchor.constraint(equalTo: babyInfoView.topAnchor, constant: 16),
            babyNameLabel.leadingAnchor.constraint(equalTo: babyAvatarImageView.trailingAnchor, constant: 16),
            babyNameLabel.trailingAnchor.constraint(equalTo: babyInfoView.trailingAnchor, constant: -16),
            
            // 寶寶年齡標籤
            babyAgeLabel.topAnchor.constraint(equalTo: babyNameLabel.bottomAnchor, constant: 4),
            babyAgeLabel.leadingAnchor.constraint(equalTo: babyAvatarImageView.trailingAnchor, constant: 16),
            babyAgeLabel.trailingAnchor.constraint(equalTo: babyInfoView.trailingAnchor, constant: -16),
            
            // 最近活動標籤
            recentActivitiesLabel.topAnchor.constraint(equalTo: babyInfoView.bottomAnchor, constant: 24),
            recentActivitiesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recentActivitiesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 最近活動表格視圖
            recentActivitiesTableView.topAnchor.constraint(equalTo: recentActivitiesLabel.bottomAnchor, constant: 8),
            recentActivitiesTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            recentActivitiesTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            recentActivitiesTableView.heightAnchor.constraint(equalToConstant: 200),
            
            // 快速操作標籤
            quickActionsLabel.topAnchor.constraint(equalTo: recentActivitiesTableView.bottomAnchor, constant: 24),
            quickActionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            quickActionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 快速操作集合視圖
            quickActionsCollectionView.topAnchor.constraint(equalTo: quickActionsLabel.bottomAnchor, constant: 8),
            quickActionsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            quickActionsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            quickActionsCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
            // 今日摘要標籤
            todaySummaryLabel.topAnchor.constraint(equalTo: quickActionsCollectionView.bottomAnchor, constant: 24),
            todaySummaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            todaySummaryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 今日摘要視圖
            todaySummaryView.topAnchor.constraint(equalTo: todaySummaryLabel.bottomAnchor, constant: 8),
            todaySummaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            todaySummaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            todaySummaryView.heightAnchor.constraint(equalToConstant: 120),
            
            // 睡眠時間標籤
            sleepTimeLabel.topAnchor.constraint(equalTo: todaySummaryView.topAnchor, constant: 16),
            sleepTimeLabel.leadingAnchor.constraint(equalTo: todaySummaryView.leadingAnchor, constant: 16),
            
            // 睡眠時間值標籤
            sleepTimeValueLabel.topAnchor.constraint(equalTo: sleepTimeLabel.bottomAnchor, constant: 4),
            sleepTimeValueLabel.leadingAnchor.constraint(equalTo: todaySummaryView.leadingAnchor, constant: 16),
            
            // 餵食次數標籤
            feedingCountLabel.topAnchor.constraint(equalTo: todaySummaryView.topAnchor, constant: 16),
            feedingCountLabel.leadingAnchor.constraint(equalTo: todaySummaryView.centerXAnchor),
            
            // 餵食次數值標籤
            feedingCountValueLabel.topAnchor.con
(Content truncated due to size limit. Use line ranges to read in chunks)