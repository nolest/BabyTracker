import UIKit

/// 成長記錄視圖控制器
class GrowthRecordViewController: UIViewController {
    // MARK: - 屬性
    
    /// 視圖模型
    private let viewModel: GrowthRecordViewModel
    
    /// 日期選擇器
    private let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        return datePicker
    }()
    
    /// 身高標籤
    private let heightLabel: UILabel = {
        let label = UILabel()
        label.text = "身高 (cm)"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 身高文本框
    private let heightTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "輸入身高"
        textField.keyboardType = .decimalPad
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    /// 體重標籤
    private let weightLabel: UILabel = {
        let label = UILabel()
        label.text = "體重 (kg)"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 體重文本框
    private let weightTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "輸入體重"
        textField.keyboardType = .decimalPad
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    /// 頭圍標籤
    private let headCircumferenceLabel: UILabel = {
        let label = UILabel()
        label.text = "頭圍 (cm)"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 頭圍文本框
    private let headCircumferenceTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "輸入頭圍"
        textField.keyboardType = .decimalPad
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    /// 備註標籤
    private let notesLabel: UILabel = {
        let label = UILabel()
        label.text = "備註"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 備註文本視圖
    private let notesTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    /// 保存按鈕
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
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
    init(viewModel: GrowthRecordViewModel) {
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
        setupKeyboardDismissal()
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        view.backgroundColor = .white
        
        // 設置導航欄標題
        title = viewModel.isEditing ? "編輯成長記錄" : "新增成長記錄"
        
        // 添加子視圖
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(datePicker)
        contentView.addSubview(heightLabel)
        contentView.addSubview(heightTextField)
        contentView.addSubview(weightLabel)
        contentView.addSubview(weightTextField)
        contentView.addSubview(headCircumferenceLabel)
        contentView.addSubview(headCircumferenceTextField)
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
            
            // 日期選擇器
            datePicker.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 身高標籤
            heightLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 20),
            heightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            heightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 身高文本框
            heightTextField.topAnchor.constraint(equalTo: heightLabel.bottomAnchor, constant: 8),
            heightTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            heightTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            heightTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // 體重標籤
            weightLabel.topAnchor.constraint(equalTo: heightTextField.bottomAnchor, constant: 20),
            weightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 體重文本框
            weightTextField.topAnchor.constraint(equalTo: weightLabel.bottomAnchor, constant: 8),
            weightTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weightTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weightTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // 頭圍標籤
            headCircumferenceLabel.topAnchor.constraint(equalTo: weightTextField.bottomAnchor, constant: 20),
            headCircumferenceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headCircumferenceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 頭圍文本框
            headCircumferenceTextField.topAnchor.constraint(equalTo: headCircumferenceLabel.bottomAnchor, constant: 8),
            headCircumferenceTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headCircumferenceTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            headCircumferenceTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // 備註標籤
            notesLabel.topAnchor.constraint(equalTo: headCircumferenceTextField.bottomAnchor, constant: 20),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 備註文本視圖
            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // 保存按鈕
            saveButton.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // 添加保存按鈕動作
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // 如果是編輯模式，填充現有數據
        if viewModel.isEditing {
            datePicker.date = viewModel.date
            heightTextField.text = viewModel.height != nil ? String(viewModel.height!) : ""
            weightTextField.text = viewModel.weight != nil ? String(viewModel.weight!) : ""
            headCircumferenceTextField.text = viewModel.headCircumference != nil ? String(viewModel.headCircumference!) : ""
            notesTextView.text = viewModel.notes
        }
    }
    
    /// 設置綁定
    private func setupBindings() {
        // 保存成功處理
        viewModel.onSaveSuccess = { [weak self] in
            // 顯示成功提示
            let alertController = UIAlertController(
                title: "成功",
                message: "成長記錄已保存",
                preferredStyle: .alert
            )
            
            alertController.addAction(UIAlertAction(title: "確定", style: .default) { _ in
                // 返回上一頁
                self?.navigationController?.popViewController(animated: true)
            })
            
            self?.present(alertController, animated: true)
        }
        
        // 保存失敗處理
        viewModel.onSaveError = { [weak self] error in
            // 顯示錯誤提示
            let alertController = UIAlertController(
                title: "錯誤",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            
            alertController.addAction(UIAlertAction(title: "確定", style: .default))
            
            self?.present(alertController, animated: true)
        }
    }
    
    /// 設置鍵盤消失
    private func setupKeyboardDismissal() {
        // 添加點擊手勢
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - 動作
    
    /// 保存按鈕點擊
    @objc private func saveButtonTapped() {
        // 獲取輸入值
        let date = datePicker.date
        let height = Double(heightTextField.text ?? "")
        let weight = Double(weightTextField.text ?? "")
        let headCircumference = Double(headCircumferenceTextField.text ?? "")
        let notes = notesTextView.text
        
        // 保存記錄
        viewModel.saveGrowthRecord(
            date: date,
            height: height,
            weight: weight,
            headCircumference: headCircumference,
            notes: notes
        )
    }
    
    /// 消失鍵盤
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
