import UIKit

/// 活動記錄視圖控制器
class ActivityRecordViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: ActivityRecordViewModel
    
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
    
    /// 活動類型標籤
    private let activityTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "活動類型"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動類型分段控制器
    private let activityTypeSegmentedControl: UISegmentedControl = {
        let items = ["尿布", "洗澡", "玩耍", "其他"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    /// 活動名稱標籤
    private let activityNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "活動名稱"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動名稱文本字段
    private let activityNameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.placeholder = "輸入活動名稱"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
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
    init(viewModel: ActivityRecordViewModel = ActivityRecordViewModel()) {
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
        contentView.addSubview(activityTypeLabel)
        contentView.addSubview(activityTypeSegmentedControl)
        contentView.addSubview(activityNameLabel)
        contentView.addSubview(activityNameTextField)
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
            
            // 活動類型標籤
            activityTypeLabel.topAnchor.constraint(equalTo: endTimePicker.bottomAnchor, constant: 16),
            activityTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            activityTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 活動類型分段控制器
            activityTypeSegmentedControl.topAnchor.constraint(equalTo: activityTypeLabel.bottomAnchor, constant: 8),
            activityTypeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            activityTypeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 活動名稱標籤
            activityNameLabel.topAnchor.constraint(equalTo: activityTypeSegmentedControl.bottomAnchor, constant: 16),
            activityNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            activityNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 活動名稱文本字段
            activityNameTextField.topAnchor.constraint(equalTo: activityNameLabel.bottomAnchor, constant: 8),
            activityNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            activityNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 備註標籤
            notesLabel.topAnchor.constraint(equalTo: activityNameTextField.bottomAnchor, constant: 16),
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
        navigationItem.title = "活動記錄"
        
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
                let alert = UIAlertController(title: "成功", message: "活動記錄已保存", preferredStyle: .alert)
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
        
        // 活動類型分段控制器
        activityTypeSegmentedControl.addTarget(self, action: #selector(activityTypeChanged), for: .valueChanged)
        
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
        
        // 更新活動類型分段控制器
        switch viewModel.activityType {
        case .diaper:
            activityTypeSegmentedControl.selectedSegmentIndex = 0
            activityNameTextField.text = "尿布更換"
        case .bath:
            activityTypeSegmentedControl.selectedSegmentIndex = 1
            activityNameTextField.text = "洗澡"
        case .play:
            activityTypeSegmentedControl.selectedSegmentIndex = 2
            activityNameTextField.text = "玩耍"
        case .other:
            activityTypeSegmentedControl.selectedSegmentIndex = 3
            activityNameTextField.text = viewModel.activityName
        default:
            activityTypeSegmentedControl.selectedSegmentIndex = 3
            activityNameTextField.text = viewModel.activityName
        }
        
        // 更新備註文本視圖
        notesTextView.text = viewModel.notes
    }
    
    // MARK: - 動作處理
    
    /// 開始時間變更
    @objc private func startTimeChanged() {
        viewModel.startTime = startTimePicker.date
    }
    
    /// 結束時間變更
    @objc private func endTimeChanged() {
        viewModel.endTime = endTimePicker.date
    }
    
    /// 活動類型變更
    @objc private func activityTypeChanged() {
        switch activityTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            viewModel.activityType = .diaper
            activityNameTextField.text = "尿布更換"
        case 1:
            viewModel.activityType = .bath
            activityNameTextField.text = "洗澡"
        case 2:
            viewModel.activityType = .play
            activityNameTextField.text = "玩耍"
        case 3:
            viewModel.activityType = .other
            activityNameTextField.text = ""
        default:
            viewModel.activityType = .other
            activityNameTextField.text = ""
        }
    }
    
    /// 隱藏鍵盤
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    /// 保存按鈕點擊
    @objc private func saveButtonTapped() {
        // 獲取活動名稱
        viewModel.activityName = activityNameTextField.text ?? ""
        
        // 獲取備註
        viewModel.notes = notesTextView.text
        
        // 保存記錄
        viewModel.saveRecord()
    }
    
    /// 取消按鈕點擊
    @objc private func cancelButtonTapped() {
        // 返回上一頁
        navigationController?.popViewController(animated: true)
    }
}
