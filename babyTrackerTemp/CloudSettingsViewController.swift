import UIKit
import Combine

class CloudSettingsViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: CloudSettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let cloudSyncSwitch = UISwitch()
    private let cloudSyncLabel = UILabel()
    private let cloudAnalysisSwitch = UISwitch()
    private let cloudAnalysisLabel = UILabel()
    private let apiKeyTextField = UITextField()
    private let apiKeyLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Initialization
    init(viewModel: CloudSettingsViewModel) {
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
        viewModel.loadSettings()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "雲端設置"
        
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
        titleLabel.text = "雲端服務設置"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        contentView.addSubview(titleLabel)
        
        // Setup cloud sync controls
        cloudSyncLabel.translatesAutoresizingMaskIntoConstraints = false
        cloudSyncLabel.text = "啟用雲端同步"
        cloudSyncLabel.font = UIFont.systemFont(ofSize: 17)
        contentView.addSubview(cloudSyncLabel)
        
        cloudSyncSwitch.translatesAutoresizingMaskIntoConstraints = false
        cloudSyncSwitch.addTarget(self, action: #selector(cloudSyncToggled), for: .valueChanged)
        contentView.addSubview(cloudSyncSwitch)
        
        // Setup cloud analysis controls
        cloudAnalysisLabel.translatesAutoresizingMaskIntoConstraints = false
        cloudAnalysisLabel.text = "啟用雲端AI分析"
        cloudAnalysisLabel.font = UIFont.systemFont(ofSize: 17)
        contentView.addSubview(cloudAnalysisLabel)
        
        cloudAnalysisSwitch.translatesAutoresizingMaskIntoConstraints = false
        cloudAnalysisSwitch.addTarget(self, action: #selector(cloudAnalysisToggled), for: .valueChanged)
        contentView.addSubview(cloudAnalysisSwitch)
        
        // Setup API key controls
        apiKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        apiKeyLabel.text = "API密鑰"
        apiKeyLabel.font = UIFont.systemFont(ofSize: 17)
        contentView.addSubview(apiKeyLabel)
        
        apiKeyTextField.translatesAutoresizingMaskIntoConstraints = false
        apiKeyTextField.placeholder = "輸入您的Deepseek API密鑰"
        apiKeyTextField.borderStyle = .roundedRect
        apiKeyTextField.isSecureTextEntry = true
        apiKeyTextField.clearButtonMode = .whileEditing
        apiKeyTextField.returnKeyType = .done
        apiKeyTextField.delegate = self
        contentView.addSubview(apiKeyTextField)
        
        // Setup save button
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("保存設置", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        contentView.addSubview(saveButton)
        
        // Setup status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 15)
        statusLabel.isHidden = true
        contentView.addSubview(statusLabel)
        
        // Setup loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        contentView.addSubview(loadingIndicator)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            cloudSyncLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            cloudSyncLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            cloudSyncSwitch.centerYAnchor.constraint(equalTo: cloudSyncLabel.centerYAnchor),
            cloudSyncSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            cloudAnalysisLabel.topAnchor.constraint(equalTo: cloudSyncLabel.bottomAnchor, constant: 25),
            cloudAnalysisLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            cloudAnalysisSwitch.centerYAnchor.constraint(equalTo: cloudAnalysisLabel.centerYAnchor),
            cloudAnalysisSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            apiKeyLabel.topAnchor.constraint(equalTo: cloudAnalysisLabel.bottomAnchor, constant: 25),
            apiKeyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            apiKeyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            apiKeyTextField.topAnchor.constraint(equalTo: apiKeyLabel.bottomAnchor, constant: 10),
            apiKeyTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            apiKeyTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            apiKeyTextField.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: apiKeyTextField.bottomAnchor, constant: 40),
            saveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            statusLabel.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 10)
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
        
        viewModel.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let message = message {
                    self?.statusLabel.text = message
                    self?.statusLabel.isHidden = false
                    
                    // Determine status type and set color
                    if message.contains("成功") {
                        self?.statusLabel.textColor = .systemGreen
                    } else if message.contains("錯誤") {
                        self?.statusLabel.textColor = .systemRed
                    } else {
                        self?.statusLabel.textColor = .systemBlue
                    }
                } else {
                    self?.statusLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        viewModel.$cloudSyncEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.cloudSyncSwitch.isOn = isEnabled
            }
            .store(in: &cancellables)
        
        viewModel.$cloudAnalysisEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.cloudAnalysisSwitch.isOn = isEnabled
            }
            .store(in: &cancellables)
        
        viewModel.$apiKey
            .receive(on: DispatchQueue.main)
            .sink { [weak self] apiKey in
                self?.apiKeyTextField.text = apiKey
            }
            .store(in: &cancellables)
    }
    
    private func updateUIState(isLoading: Bool) {
        let isEnabled = !isLoading
        cloudSyncSwitch.isEnabled = isEnabled
        cloudAnalysisSwitch.isEnabled = isEnabled
        apiKeyTextField.isEnabled = isEnabled
        saveButton.isEnabled = isEnabled
        
        // Adjust alpha for visual feedback
        saveButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    // MARK: - Actions
    @objc private func cloudSyncToggled() {
        viewModel.setCloudSyncEnabled(cloudSyncSwitch.isOn)
    }
    
    @objc private func cloudAnalysisToggled() {
        viewModel.setCloudAnalysisEnabled(cloudAnalysisSwitch.isOn)
    }
    
    @objc private func saveButtonTapped() {
        guard let apiKey = apiKeyTextField.text else { return }
        viewModel.saveSettings(apiKey: apiKey)
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension CloudSettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
