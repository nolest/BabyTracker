import UIKit

class CustomTextField: UITextField {
    
    // MARK: - Properties
    private let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    private let placeholderLabel = UILabel()
    private let errorLabel = UILabel()
    private let underlineView = UIView()
    
    var errorText: String? {
        didSet {
            updateErrorState()
        }
    }
    
    var floatingPlaceholder: Bool = true {
        didSet {
            updatePlaceholderState()
        }
    }
    
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
        borderStyle = .none
        backgroundColor = .clear
        
        // Setup underline
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        underlineView.backgroundColor = .systemGray4
        addSubview(underlineView)
        
        // Setup floating placeholder
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.font = UIFont.systemFont(ofSize: 12)
        placeholderLabel.textColor = .systemGray
        placeholderLabel.alpha = 0
        addSubview(placeholderLabel)
        
        // Setup error label
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = UIFont.systemFont(ofSize: 12)
        errorLabel.textColor = .systemRed
        errorLabel.alpha = 0
        addSubview(errorLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            underlineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            underlineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 1),
            
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: -15),
            
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
            errorLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 4)
        ])
        
        // Add target for text changes
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        addTarget(self, action: #selector(textDidBeginEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(textDidEndEditing), for: .editingDidEnd)
    }
    
    // MARK: - Text Rect
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    // MARK: - Text Handling
    @objc private func textDidChange() {
        updatePlaceholderState()
    }
    
    @objc private func textDidBeginEditing() {
        underlineView.backgroundColor = tintColor
        updatePlaceholderState()
    }
    
    @objc private func textDidEndEditing() {
        underlineView.backgroundColor = .systemGray4
        updatePlaceholderState()
    }
    
    // MARK: - State Updates
    private func updatePlaceholderState() {
        if floatingPlaceholder {
            if let placeholder = placeholder {
                placeholderLabel.text = placeholder
                self.attributedPlaceholder = nil
                
                if let text = text, !text.isEmpty {
                    // Show floating placeholder
                    UIView.animate(withDuration: 0.2) {
                        self.placeholderLabel.alpha = 1
                    }
                } else if isFirstResponder {
                    // Show floating placeholder when editing
                    UIView.animate(withDuration: 0.2) {
                        self.placeholderLabel.alpha = 1
                    }
                } else {
                    // Hide floating placeholder, show normal placeholder
                    UIView.animate(withDuration: 0.2) {
                        self.placeholderLabel.alpha = 0
                    }
                    self.attributedPlaceholder = NSAttributedString(
                        string: placeholder,
                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
                    )
                }
            }
        } else {
            // Use standard placeholder
            placeholderLabel.alpha = 0
            if let placeholder = placeholder {
                self.attributedPlaceholder = NSAttributedString(
                    string: placeholder,
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
                )
            }
        }
    }
    
    private func updateErrorState() {
        if let errorText = errorText, !errorText.isEmpty {
            errorLabel.text = errorText
            UIView.animate(withDuration: 0.2) {
                self.errorLabel.alpha = 1
                self.underlineView.backgroundColor = .systemRed
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.errorLabel.alpha = 0
                self.underlineView.backgroundColor = self.isFirstResponder ? self.tintColor : .systemGray4
            }
        }
    }
    
    // MARK: - Public Methods
    func setPlaceholder(_ text: String) {
        placeholder = text
        updatePlaceholderState()
    }
    
    func clearError() {
        errorText = nil
    }
}
