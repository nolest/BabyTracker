import UIKit
import Combine

class PredictionViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PredictionViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["睡眠", "餵食", "活動"])
    private let timeframeLabel = UILabel()
    private let timeframePicker = UIDatePicker()
    private let predictionCard = UIView()
    private let predictionTitleLabel = UILabel()
    private let predictionDescriptionLabel = UILabel()
    private let confidenceLabel = UILabel()
    private let confidenceProgressView = UIProgressView(progressViewStyle: .bar)
    private let refreshButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    
    // MARK: - Initialization
    init(viewModel: PredictionViewModel) {
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
        viewModel.loadPredictions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "智能預測"
        
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
        titleLabel.text = "寶寶行為預測"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        // Setup segmented control
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        contentView.addSubview(segmentedControl)
        
        // Setup timeframe label
        timeframeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeframeLabel.text = "預測時間範圍"
        timeframeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(timeframeLabel)
        
        // Setup timeframe picker
        timeframePicker.translatesAutoresizingMaskIntoConstraints = false
        timeframePicker.datePickerMode = .dateAndTime
        timeframePicker.preferredDatePickerStyle = .compact
        timeframePicker.minimumDate = Date()
        timeframePicker.addTarget(self, action: #selector(timeframeChanged), for: .valueChanged)
        contentView.addSubview(timeframePicker)
        
        // Setup prediction card
        setupPredictionCard()
        
        // Setup refresh button
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.setTitle("重新生成預測", for: .normal)
        refreshButton.backgroundColor = .systemBlue
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.layer.cornerRadius = 10
        refreshButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        contentView.addSubview(refreshButton)
        
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
            
            timeframeLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            timeframeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            timeframePicker.centerYAnchor.constraint(equalTo: timeframeLabel.centerYAnchor),
            timeframePicker.leadingAnchor.constraint(equalTo: timeframeLabel.trailingAnchor, constant: 10),
            timeframePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            predictionCard.topAnchor.constraint(equalTo: timeframeLabel.bottomAnchor, constant: 20),
            predictionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            predictionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            refreshButton.topAnchor.constraint(equalTo: predictionCard.bottomAnchor, constant: 30),
            refreshButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 200),
            refreshButton.heightAnchor.constraint(equalToConstant: 50),
            refreshButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            errorLabel.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 20),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupPredictionCard() {
        predictionCard.translatesAutoresizingMaskIntoConstraints = false
        predictionCard.backgroundColor = .systemGray6
        predictionCard.layer.cornerRadius = 12
        predictionCard.layer.shadowColor = UIColor.black.cgColor
        predictionCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        predictionCard.layer.shadowRadius = 4
        predictionCard.layer.shadowOpacity = 0.1
        contentView.addSubview(predictionCard)
        
        // Setup prediction title label
        predictionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        predictionTitleLabel.text = "預測結果"
        predictionTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        predictionCard.addSubview(predictionTitleLabel)
        
        // Setup prediction description label
        predictionDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        predictionDescriptionLabel.text = "尚未生成預測"
        predictionDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        predictionDescriptionLabel.numberOfLines = 0
        predictionCard.addSubview(predictionDescriptionLabel)
        
        // Setup confidence label
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        confidenceLabel.text = "準確度: 0%"
        confidenceLabel.font = UIFont.systemFont(ofSize: 14)
        confidenceLabel.textColor = .systemGray
        predictionCard.addSubview(confidenceLabel)
        
        // Setup confidence progress view
        confidenceProgressView.translatesAutoresizingMaskIntoConstraints = false
        confidenceProgressView.progress = 0
        confidenceProgressView.progressTintColor = .systemGreen
        predictionCard.addSubview(confidenceProgressView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            predictionCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            
            predictionTitleLabel.topAnchor.constraint(equalTo: predictionCard.topAnchor, constant: 15),
            predictionTitleLabel.leadingAnchor.constraint(equalTo: predictionCard.leadingAnchor, constant: 15),
            predictionTitleLabel.trailingAnchor.constraint(equalTo: predictionCard.trailingAnchor, constant: -15),
            
            predictionDescriptionLabel.topAnchor.constraint(equalTo: predictionTitleLabel.bottomAnchor, constant: 10),
            predictionDescriptionLabel.leadingAnchor.constraint(equalTo: predictionCard.leadingAnchor, constant: 15),
            predictionDescriptionLabel.trailingAnchor.constraint(equalTo: predictionCard.trailingAnchor, constant: -15),
            
            confidenceLabel.topAnchor.constraint(equalTo: predictionDescriptionLabel.bottomAnchor, constant: 15),
            confidenceLabel.leadingAnchor.constraint(equalTo: predictionCard.leadingAnchor, constant: 15),
            confidenceLabel.trailingAnchor.constraint(equalTo: predictionCard.trailingAnchor, constant: -15),
            
            confidenceProgressView.topAnchor.constraint(equalTo: confidenceLabel.bottomAnchor, constant: 5),
            confidenceProgressView.leadingAnchor.constraint(equalTo: predictionCard.leadingAnchor, constant: 15),
            confidenceProgressView.trailingAnchor.constraint(equalTo: predictionCard.trailingAnchor, constant: -15),
            confidenceProgressView.bottomAnchor.constraint(equalTo: predictionCard.bottomAnchor, constant: -15)
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
        
        viewModel.$currentPrediction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] prediction in
                self?.updatePredictionUI(with: prediction)
            }
            .store(in: &cancellables)
    }
    
    private func updateUIState(isLoading: Bool) {
        let isEnabled = !isLoading
        segmentedControl.isEnabled = isEnabled
        timeframePicker.isEnabled = isEnabled
        refreshButton.isEnabled = isEnabled
        
        // Adjust alpha for visual feedback
        let alpha: CGFloat = isEnabled ? 1.0 : 0.5
        segmentedControl.alpha = alpha
        timeframePicker.alpha = alpha
        refreshButton.alpha = alpha
    }
    
    private func updatePredictionUI(with prediction: PredictionViewModel.PredictionDisplay?) {
        guard let prediction = prediction else {
            predictionTitleLabel.text = "預測結果"
            predictionDescriptionLabel.text = "尚未生成預測"
            confidenceLabel.text = "準確度: 0%"
            confidenceProgressView.progress = 0
            return
        }
        
        predictionTitleLabel.text = prediction.title
        predictionDescriptionLabel.text = prediction.description
        confidenceLabel.text = "準確度: \(Int(prediction.confidence * 100))%"
        confidenceProgressView.progress = prediction.confidence
        
        // Update progress view color based on confidence
        if prediction.confidence < 0.4 {
            confidenceProgressView.progressTintColor = .systemRed
        } else if prediction.confidence < 0.7 {
            confidenceProgressView.progressTintColor = .systemYellow
        } else {
            confidenceProgressView.progressTintColor = .systemGreen
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        viewModel.updatePredictionType(index: segmentedControl.selectedSegmentIndex)
    }
    
    @objc private func timeframeChanged() {
        viewModel.updateTimeframe(date: timeframePicker.date)
    }
    
    @objc private func refreshTapped() {
        viewModel.loadPredictions()
    }
}
