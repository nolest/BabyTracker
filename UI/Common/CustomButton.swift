import UIKit

class CustomButton: UIButton {
    
    // MARK: - Button Types
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        case outline
    }
    
    // MARK: - Properties
    private var style: ButtonStyle = .primary
    private var isLoading: Bool = false
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Initialization
    init(style: ButtonStyle = .primary, title: String? = nil) {
        super.init(frame: .zero)
        self.style = style
        setup()
        setTitle(title, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    private func setup() {
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = 10
        clipsToBounds = true
        
        // Setup activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        applyStyle()
    }
    
    private func applyStyle() {
        switch style {
        case .primary:
            backgroundColor = .systemBlue
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray4, for: .disabled)
            
        case .secondary:
            backgroundColor = .systemGray4
            setTitleColor(.black, for: .normal)
            setTitleColor(.black.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray, for: .disabled)
            
        case .danger:
            backgroundColor = .systemRed
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray4, for: .disabled)
            
        case .outline:
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = UIColor.systemBlue.cgColor
            setTitleColor(.systemBlue, for: .normal)
            setTitleColor(.systemBlue.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray, for: .disabled)
        }
    }
    
    // MARK: - Public Methods
    func setStyle(_ style: ButtonStyle) {
        self.style = style
        applyStyle()
    }
    
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
        
        if isLoading {
            activityIndicator.startAnimating()
            titleLabel?.alpha = 0
            isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            titleLabel?.alpha = 1
            isEnabled = true
        }
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update corner radius if height changes
        layer.cornerRadius = bounds.height / 4
    }
    
    // MARK: - State
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.6
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        }
    }
}
