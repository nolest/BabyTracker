import UIKit
import Combine

class AnalysisDashboardViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: AnalysisDashboardViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let sleepAnalysisButton = UIButton(type: .system)
    private let feedingAnalysisButton = UIButton(type: .system)
    private let activityAnalysisButton = UIButton(type: .system)
    private let predictionButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    
    // MARK: - Initialization
    init(viewModel: AnalysisDashboardViewModel) {
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
        title = "分析儀表板"
        
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
        titleLabel.text = "寶寶生活分析"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        // Setup analysis buttons
        setupButton(sleepAnalysisButton, title: "睡眠分析", action: #selector(sleepAnalysisTapped))
        setupButton(feedingAnalysisButton, title: "餵食分析", action: #selector(feedingAnalysisTapped))
        setupButton(activityAnalysisButton, title: "活動分析", action: #selector(activityAnalysisTapped))
        setupButton(predictionButton, title: "智能預測", action: #selector(predictionTapped))
        
        // Add buttons to content view
        contentView.addSubview(sleepAnalysisButton)
        contentView.addSubview(feedingAnalysisButton)
        contentView.addSubview(activityAnalysisButton)
        contentView.addSubview(predictionButton)
        
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
            
            sleepAnalysisButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            sleepAnalysisButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sleepAnalysisButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sleepAnalysisButton.heightAnchor.constraint(equalToConstant: 60),
            
            feedingAnalysisButton.topAnchor.constraint(equalTo: sleepAnalysisButton.bottomAnchor, constant: 20),
            feedingAnalysisButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            feedingAnalysisButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            feedingAnalysisButton.heightAnchor.constraint(equalToConstant: 60),
            
            activityAnalysisButton.topAnchor.constraint(equalTo: feedingAnalysisButton.bottomAnchor, constant: 20),
            activityAnalysisButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityAnalysisButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            activityAnalysisButton.heightAnchor.constraint(equalToConstant: 60),
            
            predictionButton.topAnchor.constraint(equalTo: activityAnalysisButton.bottomAnchor, constant: 20),
            predictionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            predictionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            predictionButton.heightAnchor.constraint(equalToConstant: 60),
            predictionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            errorLabel.topAnchor.constraint(equalTo: predictionButton.bottomAnchor, constant: 20),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
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
    }
    
    private func updateUIState(isLoading: Bool) {
        let isEnabled = !isLoading
        sleepAnalysisButton.isEnabled = isEnabled
        feedingAnalysisButton.isEnabled = isEnabled
        activityAnalysisButton.isEnabled = isEnabled
        predictionButton.isEnabled = isEnabled
        
        // Adjust alpha for visual feedback
        let alpha: CGFloat = isEnabled ? 1.0 : 0.5
        sleepAnalysisButton.alpha = alpha
        feedingAnalysisButton.alpha = alpha
        activityAnalysisButton.alpha = alpha
        predictionButton.alpha = alpha
    }
    
    // MARK: - Actions
    @objc private func sleepAnalysisTapped() {
        viewModel.navigateToSleepAnalysis()
    }
    
    @objc private func feedingAnalysisTapped() {
        viewModel.navigateToFeedingAnalysis()
    }
    
    @objc private func activityAnalysisTapped() {
        viewModel.navigateToActivityAnalysis()
    }
    
    @objc private func predictionTapped() {
        viewModel.navigateToPrediction()
    }
}
