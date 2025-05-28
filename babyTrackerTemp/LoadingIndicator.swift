import UIKit

class LoadingIndicator: UIView {
    
    // MARK: - Properties
    private let activityIndicator = UIActivityIndicatorView()
    private let messageLabel = UILabel()
    private let blurEffect = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    
    var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = message == nil
            layoutIfNeeded()
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
        // Setup blur effect
        blurEffect.translatesAutoresizingMaskIntoConstraints = false
        blurEffect.layer.cornerRadius = 10
        blurEffect.clipsToBounds = true
        addSubview(blurEffect)
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.style = .large
        activityIndicator.color = .systemBlue
        activityIndicator.hidesWhenStopped = true
        blurEffect.contentView.addSubview(activityIndicator)
        
        // Setup message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .label
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = true
        blurEffect.contentView.addSubview(messageLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            blurEffect.centerXAnchor.constraint(equalTo: centerXAnchor),
            blurEffect.centerYAnchor.constraint(equalTo: centerYAnchor),
            blurEffect.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            blurEffect.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            activityIndicator.centerXAnchor.constraint(equalTo: blurEffect.contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: blurEffect.contentView.topAnchor, constant: 20),
            
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: blurEffect.contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: blurEffect.contentView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: blurEffect.contentView.bottomAnchor, constant: -16)
        ])
        
        // Add constraint to ensure minimum size when no message
        let bottomConstraint = activityIndicator.bottomAnchor.constraint(equalTo: blurEffect.contentView.bottomAnchor, constant: -20)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true
    }
    
    // MARK: - Public Methods
    func startAnimating() {
        isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicator.stopAnimating()
        isHidden = true
    }
    
    // MARK: - Static Helper Methods
    
    /// Show loading indicator on a view controller
    static func show(on viewController: UIViewController, message: String? = nil) -> LoadingIndicator {
        let loadingIndicator = LoadingIndicator()
        loadingIndicator.message = message
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            loadingIndicator.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        loadingIndicator.startAnimating()
        return loadingIndicator
    }
}
