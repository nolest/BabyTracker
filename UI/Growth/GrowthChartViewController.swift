import UIKit

class GrowthChartViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: GrowthChartViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["身高", "體重", "頭圍"])
    private let timeRangeSegmentedControl = UISegmentedControl(items: ["1個月", "3個月", "6個月", "1年", "全部"])
    private let chartContainerView = UIView()
    private let chartView = ChartView(title: "成長圖表")
    private let percentileLabel = UILabel()
    private let averageLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    
    // MARK: - Initialization
    init(viewModel: GrowthChartViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "成長圖表"
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Setup title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "寶寶成長趨勢"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        // Setup segmented controls
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(growthTypeChanged), for: .valueChanged)
        contentView.addSubview(segmentedControl)
        
        timeRangeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        timeRangeSegmentedControl.selectedSegmentIndex = 2 // Default to 6 months
        timeRangeSegmentedControl.addTarget(self, action: #selector(timeRangeChanged), for: .valueChanged)
        contentView.addSubview(timeRangeSegmentedControl)
        
        // Setup chart container
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.backgroundColor = .systemGray6
        chartContainerView.layer.cornerRadius = 12
        chartContainerView.layer.shadowColor = UIColor.black.cgColor
        chartContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        chartContainerView.layer.shadowRadius = 4
        chartContainerView.layer.shadowOpacity = 0.1
        contentView.addSubview(chartContainerView)
        
        // Setup chart view
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(chartView)
        
        // Setup percentile label
        percentileLabel.translatesAutoresizingMaskIntoConstraints = false
        percentileLabel.text = "百分位: --"
        percentileLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(percentileLabel)
        
        // Setup average label
        averageLabel.translatesAutoresizingMaskIntoConstraints = false
        averageLabel.text = "平均值: --"
        averageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(averageLabel)
        
        // Setup loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        contentView.addSubview(loadingIndicator)
        
        // Setup error label
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        contentView.addSubview(errorLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeRangeSegmentedControl.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 15),
            timeRangeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeRangeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            chartContainerView.topAnchor.constraint(equalTo: timeRangeSegmentedControl.bottomAnchor, constant: 20),
            chartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chartContainerView.heightAnchor.constraint(equalToConstant: 300),
            
            chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor, constant: 10),
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor, constant: 10),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor, constant: -10),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: -10),
            
            percentileLabel.topAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 20),
            percentileLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            averageLabel.topAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 20),
            averageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: chartContainerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: chartContainerView.centerYAnchor),
            
            errorLabel.topAnchor.constraint(equalTo: percentileLabel.bottomAnchor, constant: 20),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            errorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
                self?.updateUIState(isLoading: isLoading)
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorLabel.text = "錯誤: \(error.localizedDescription)"
                    self?.errorLabel.isHidden = false
                } else {
                    self?.errorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        viewModel.$chartData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (chartData: ChartView.ChartData?) in
                if let chartData = chartData {
                    self?.chartView.updateChart(with: chartData)
                    self?.updateStatistics(with: chartData)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateUIState(isLoading: Bool) {
        let isEnabled = !isLoading
        segmentedControl.isEnabled = isEnabled
        timeRangeSegmentedControl.isEnabled = isEnabled
        
        // Adjust alpha for visual feedback
        let alpha: CGFloat = isEnabled ? 1.0 : 0.5
        segmentedControl.alpha = alpha
        timeRangeSegmentedControl.alpha = alpha
        chartContainerView.alpha = alpha
    }
    
    private func updateStatistics(with chartData: ChartView.ChartData) {
        percentileLabel.text = "百分位: \(chartData.percentile ?? "--")"
        averageLabel.text = "平均值: \(chartData.average ?? "--")"
    }
    
    // MARK: - Actions
    @objc private func growthTypeChanged() {
        viewModel.updateGrowthType(index: segmentedControl.selectedSegmentIndex)
    }
    
    @objc private func timeRangeChanged() {
        viewModel.updateTimeRange(index: timeRangeSegmentedControl.selectedSegmentIndex)
    }
}

// MARK: - Import for Combine
import Combine
