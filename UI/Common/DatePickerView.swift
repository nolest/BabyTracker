import UIKit

class DatePickerView: UIView {
    
    // MARK: - Properties
    private let titleLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let confirmButton = CustomButton(style: .primary, title: "確定")
    private let cancelButton = CustomButton(style: .outline, title: "取消")
    private let containerView = UIView()
    private let backgroundView = UIView()
    
    var onDateSelected: ((Date) -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    private func setup() {
        // Setup background view (semi-transparent overlay)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(backgroundView)
        
        // Setup container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        // Setup title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "選擇日期"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        // Setup date picker
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        containerView.addSubview(datePicker)
        
        // Setup buttons
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 10
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)
        containerView.addSubview(buttonStackView)
        
        // Add tap gesture to background for dismissal
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            datePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            datePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            buttonStackView.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Public Methods
    func configure(title: String = "選擇日期", mode: UIDatePicker.Mode = .dateAndTime, 
                   minimumDate: Date? = nil, maximumDate: Date? = nil, initialDate: Date = Date()) {
        titleLabel.text = title
        datePicker.datePickerMode = mode
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate
        datePicker.date = initialDate
        
        // Adjust picker style based on mode
        if mode == .date || mode == .dateAndTime {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            datePicker.preferredDatePickerStyle = .wheels
        }
    }
    
    // MARK: - Actions
    @objc private func confirmButtonTapped() {
        onDateSelected?(datePicker.date)
        removeFromSuperview()
    }
    
    @objc private func cancelButtonTapped() {
        onCancel?()
        removeFromSuperview()
    }
    
    @objc private func backgroundTapped() {
        onCancel?()
        removeFromSuperview()
    }
    
    // MARK: - Static Helper Methods
    
    /// Show date picker on a view controller
    static func show(on viewController: UIViewController, title: String = "選擇日期", 
                     mode: UIDatePicker.Mode = .dateAndTime, minimumDate: Date? = nil, 
                     maximumDate: Date? = nil, initialDate: Date = Date(),
                     onDateSelected: @escaping (Date) -> Void, onCancel: (() -> Void)? = nil) {
        let datePickerView = DatePickerView()
        datePickerView.configure(title: title, mode: mode, minimumDate: minimumDate, 
                                maximumDate: maximumDate, initialDate: initialDate)
        datePickerView.onDateSelected = onDateSelected
        datePickerView.onCancel = onCancel
        datePickerView.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(datePickerView)
        
        NSLayoutConstraint.activate([
            datePickerView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            datePickerView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            datePickerView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            datePickerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        // Animate appearance
        datePickerView.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        datePickerView.containerView.alpha = 0
        datePickerView.backgroundView.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            datePickerView.containerView.transform = .identity
            datePickerView.containerView.alpha = 1
            datePickerView.backgroundView.alpha = 1
        }
    }
}
