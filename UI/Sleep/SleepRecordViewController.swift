import UIKit

/// 睡眠記錄視圖控制器
class SleepRecordViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: SleepRecordViewModel
    
    /// 開始時間標籤
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "開始時間"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 開始時間選擇器
    private let startTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    /// 結束時間標籤
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "結束時間"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 結束時間選擇器
    private let endTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    /// 環境因素標籤
    private let environmentFactorsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "環境因素"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 環境因素分段控制器
    private let environmentFactorsSegmentedControl: UISegmentedControl = {
        let items = ["無", "噪音", "光線", "溫度", "其他"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    /// 睡眠中斷標籤
    private let sleepInterruptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "睡眠中斷"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 睡眠中斷分段控制器
    private let sleepInterruptionSegmentedControl: UISegmentedControl = {
        let items = ["無", "哭鬧", "餵食", "換尿布", "其他"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    /// 睡眠質量標籤
    private let sleepQualityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "睡眠質量"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 睡眠質量分段控制器
    private let sleepQualitySegmentedControl: UISegmentedControl = {
        let items = ["差", "一般", "良好", "優秀"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 2
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    /// 備註標籤
    private let notesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "備註"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 備註文本視圖
    private let notesTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    /// 保存按鈕
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
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
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter viewModel: 視圖模型
    init(viewModel: SleepRecordViewModel = SleepRecordViewModel()) {
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
        
        // 設置手勢識別器
        setupGestureRecognizers()
        
        // 更新UI
        updateUI()
    }
    
    // MARK: - 私有方法
    
    /// 設置視圖
    private func setupView() {
        // 設置背景色
        view.backgroundColor = .systemBackground
        
        // 添加滾動視圖
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 添加子視圖
        contentView.addSubview(startTimeLabel)
        contentView.addSubview(startTimePicker)
        contentView.addSubview(endTimeLabel)
        contentView.addSubview(endTimePicker)
        contentView.addSubview(environmentFactorsLabel)
        contentView.addSubview(environmentFactorsSegmentedControl)
        contentView.addSubview(sleepInterruptionLabel)
        contentView.addSubview(sleepInterruptionSegmentedControl)
        contentView.addSubview(sleepQualityLabel)
        contentView.addSubview(sleepQualitySegmentedControl)
        contentView.addSubview(notesLabel)
        contentView.addSubview(notesTextView)
        contentView.addSubview(saveButton)
        
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
            
            // 開始時間標籤
            startTimeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            startTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            startTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 開始時間選擇器
            startTimePicker.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 8),
            startTimePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            startTimePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 結束時間標籤
            endTimeLabel.topAnchor.constraint(equalTo: startTimePicker.bottomAnchor, constant: 16),
            endTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            endTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 結束時間選擇器
            endTimePicker.topAnchor.constraint(equalTo: endTimeLabel.bottomAnchor, constant: 8),
            endTimePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            endTimePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 環境因素標籤
            environmentFactorsLabel.topAnchor.constraint(equalTo: endTimePicker.bottomAnchor, constant: 16),
            environmentFactorsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            environmentFactorsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 環境因素分段控制器
            environmentFactorsSegmentedControl.topAnchor.constraint(equalTo: environmentFactorsLabel.bottomAnchor, constant: 8),
            environmentFactorsSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            environmentFactorsSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 睡眠中斷標籤
            sleepInterruptionLabel.topAnchor.constraint(equalTo: environmentFactorsSegmentedControl.bottomAnchor, constant: 16),
            sleepInterruptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sleepInterruptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 睡眠中斷分段控制器
            sleepInterruptionSegmentedControl.topAnchor.constraint(equalTo: sleepInterruptionLabel.bottomAnchor, constant: 8),
            sleepInterruptionSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sleepInterruptionSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 睡眠質量標籤
            sleepQualityLabel.topAnchor.constraint(equalTo: sleepInterruptionSegmentedControl.bottomAnchor, constant: 16),
            sleepQualityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sleepQualityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 睡眠質量分段控制器
            sleepQualitySegmentedControl.topAnchor.constraint(equalTo: sleepQualityLabel.bottomAnchor, constant: 8),
            sleepQualitySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sleepQualitySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 備註標籤
            notesLabel.topAnchor.constraint(equalTo: sleepQualitySegmentedControl.bottomAnchor, constant: 16),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 備註文本視圖
            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // 保存按鈕
            saveButton.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    /// 設置導航欄
    private func setupNavigationBar() {
        // 設置標題
        navigationItem.title = "睡眠記錄"
        
        // 設置取消按鈕
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    /// 綁定視圖模型
    private func bindViewModel() {
        // 綁定保存完成
        viewModel.onSaveCompleted = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // 顯示成功提示
                let alert = UIAlertController(title: "成功", message: "睡眠記錄已保存", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default) { _ in
                    // 返回上一頁
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alert, animated: true)
                
            case .failure(let error):
                // 顯示錯誤提示
                let alert = UIAlertController(title: "錯誤", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    /// 設置動作
    private func setupActions() {
        // 開始時間選擇器
        startTimePicker.addTarget(self, action: #selector(startTimeChanged), for: .valueChanged)
        
        // 結束時間選擇器
        endTimePicker.addTarget(self, action: #selector(endTimeChanged), for: .valueChanged)
        
        // 環境因素分段控制器
        environmentFactorsSegmentedControl.addTarget(self, action: #selector(environmentFactorsChanged), for: .valueChanged)
        
        // 睡眠中斷分段控制器
        sleepInterruptionSegmentedControl.addTarget(self, action: #selector(sleepInterruptionChanged), for: .valueChanged)
        
        // 睡眠質量分段控制器
        sleepQualitySegmentedControl.addTarget(self, action: #selector(sleepQualityChanged), for: .valueChanged)
        
        // 保存按鈕
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    /// 設置手勢識別器
    private func setupGestureRecognizers() {
        // 添加點擊手勢以隱藏鍵盤
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    /// 更新UI
    private func updateUI() {
        // 更新開始時間選擇器
        startTimePicker.date = viewModel.startTime
        
        // 更新結束時間選擇器
        endTimePicker.date = viewModel.endTime
        
        // 更新環境因素分段控制器
        switch viewModel.environmentFactors {
        case .none:
            environmentFactorsSegmentedControl.selectedSegmentIndex = 0
        case .noise:
            environmentFactorsSegmentedControl.selectedSegmentIndex = 1
        case .light:
            environmentFactorsSegmentedControl.selectedSegmentIndex = 2
        case .temperature:
            environmentFactorsSegmentedControl.selectedSegmentIndex = 3
        case .other:
            environmentFactorsSegmentedControl.selectedSegmentIndex = 4
        }
        
        // 更新睡眠中斷分段控制器
        switch viewModel.sleepInterruption {
        case .none:
            sleepInterruptionSegmentedControl.selectedSegmentIndex = 0
        case .crying:
            sleepInterruptionSegmentedControl.selectedSegmentIndex = 1
        case .feeding:
            sleepInterruptionSegmentedControl.selectedSegmentInde
(Content truncated due to size limit. Use line ranges to read in chunks)