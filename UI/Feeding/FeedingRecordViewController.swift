import UIKit

/// 餵食記錄視圖控制器
class FeedingRecordViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: FeedingRecordViewModel
    
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
    
    /// 餵食類型標籤
    private let feedingTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "餵食類型"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 餵食類型分段控制器
    private let feedingTypeSegmentedControl: UISegmentedControl = {
        let items = ["母乳", "奶瓶", "配方奶", "輔食"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    /// 數量標籤
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.text = "數量 (ml)"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 數量文本字段
    private let amountTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.placeholder = "輸入數量"
        textField.keyboardType = .numberPad
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
    init(viewModel: FeedingRecordViewModel = FeedingRecordViewModel()) {
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
        contentView.addSubview(feedingTypeLabel)
        contentView.addSubview(feedingTypeSegmentedControl)
        contentView.addSubview(amountLabel)
        contentView.addSubview(amountTextField)
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
            
            // 餵食類型標籤
            feedingTypeLabel.topAnchor.constraint(equalTo: endTimePicker.bottomAnchor, constant: 16),
            feedingTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            feedingTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 餵食類型分段控制器
            feedingTypeSegmentedControl.topAnchor.constraint(equalTo: feedingTypeLabel.bottomAnchor, constant: 8),
            feedingTypeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            feedingTypeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 數量標籤
            amountLabel.topAnchor.constraint(equalTo: feedingTypeSegmentedControl.bottomAnchor, constant: 16),
            amountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 數量文本字段
            amountTextField.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 8),
            amountTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            amountTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 備註標籤
            notesLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 16),
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
        navigationItem.title = "餵食記錄"
        
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
                let alert = UIAlertController(title: "成功", message: "餵食記錄已保存", preferredStyle: .alert)
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
        
        // 餵食類型分段控制器
        feedingTypeSegmentedControl.addTarget(self, action: #selector(feedingTypeChanged), for: .valueChanged)
        
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
        
        // 更新餵食類型分段控制器
        switch viewModel.feedingType {
        case .breastfeeding:
            feedingTypeSegmentedControl.selectedSegmentIndex = 0
            amountLabel.isHidden = true
            amountTextField.isHidden = true
        case .bottleBreastMilk:
            feedingTypeSegmentedControl.selectedSegmentIndex = 1
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        case .formula:
            feedingTypeSegmentedControl.selectedSegmentIndex = 2
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        case .solidFood:
            feedingTypeSegmentedControl.selectedSegmentIndex = 3
            amountLabel.isHidden = true
            amountTextField.isHidden = true
        case .water:
            feedingTypeSegmentedControl.selectedSegmentIndex = 4
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        case .other:
            feedingTypeSegmentedControl.selectedSegmentIndex = 5
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        }
        
        // 更新數量文本字段
        if let amount = viewModel.amount {
            amountTextField.text = "\(amount)"
        } else {
            amountTextField.text = ""
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
    
    /// 餵食類型變更
    @objc private func feedingTypeChanged() {
        switch feedingTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            viewModel.feedingType = .breastfeeding
            amountLabel.isHidden = true
            amountTextField.isHidden = true
        case 1:
            viewModel.feedingType = .bottleBreastMilk
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        case 2:
            viewModel.feedingType = .formula
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        case 3:
            viewModel.feedingType = .solidFood
            amountLabel.isHidden = true
            amountTextField.isHidden = true
        case 4:
            viewModel.feedingType = .water
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        case 5:
            viewModel.feedingType = .other
            amountLabel.isHidden = false
            amountTextField.isHidden = false
        default:
            viewModel.feedingType = .breastfeeding
            amountLabel.isHidden = true
            amountTextField.isHidden = true
        }
    }
    
    /// 隱藏鍵盤
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    /// 保存按鈕點擊
    @objc private func saveButtonTapped() {
        // 獲取數量
        if !amountTextField.isHidden, let amountText = amountTextField.text, !amountText.isEmpty {
            viewModel.amount = Double(amountText)
        } else {
            viewModel.amount = nil
        }
        
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
