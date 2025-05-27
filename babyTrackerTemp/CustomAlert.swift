import UIKit

class CustomAlert {
    
    // MARK: - Alert Types
    enum AlertType {
        case success
        case error
        case warning
        case info
    }
    
    // MARK: - Properties
    private weak var parentViewController: UIViewController?
    private var alertController: UIAlertController?
    
    // MARK: - Initialization
    init(viewController: UIViewController) {
        self.parentViewController = viewController
    }
    
    // MARK: - Public Methods
    
    /// Show a simple alert with a title, message, and OK button
    func showAlert(title: String, message: String, type: AlertType = .info, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add OK action
        let okAction = UIAlertAction(title: "確定", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        
        // Style based on type
        styleAlert(alertController, type: type)
        
        // Present alert
        parentViewController?.present(alertController, animated: true)
    }
    
    /// Show a confirmation alert with Yes/No options
    func showConfirmation(title: String, message: String, confirmTitle: String = "確定", 
                          cancelTitle: String = "取消", type: AlertType = .warning, 
                          onConfirm: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add confirm action
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm()
        }
        alertController.addAction(confirmAction)
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            onCancel?()
        }
        alertController.addAction(cancelAction)
        
        // Style based on type
        styleAlert(alertController, type: type)
        
        // Present alert
        parentViewController?.present(alertController, animated: true)
    }
    
    /// Show an input alert with a text field
    func showInputAlert(title: String, message: String, placeholder: String = "", 
                        defaultText: String = "", keyboardType: UIKeyboardType = .default,
                        confirmTitle: String = "確定", cancelTitle: String = "取消",
                        onConfirm: @escaping (String) -> Void, onCancel: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add text field
        alertController.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = defaultText
            textField.keyboardType = keyboardType
            textField.clearButtonMode = .whileEditing
        }
        
        // Add confirm action
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in
            if let textField = alertController.textFields?.first, let text = textField.text {
                onConfirm(text)
            }
        }
        alertController.addAction(confirmAction)
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            onCancel?()
        }
        alertController.addAction(cancelAction)
        
        // Present alert
        parentViewController?.present(alertController, animated: true)
    }
    
    /// Show a toast message that automatically disappears
    func showToast(message: String, duration: TimeInterval = 2.0, type: AlertType = .info) {
        guard let parentView = parentViewController?.view else { return }
        
        // Create toast view
        let toastView = UIView()
        toastView.backgroundColor = getBackgroundColor(for: type)
        toastView.alpha = 0
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true
        
        // Create message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        
        // Add to view hierarchy
        toastView.addSubview(messageLabel)
        parentView.addSubview(toastView)
        
        // Configure auto layout
        toastView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toastView.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20),
            toastView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -10),
            messageLabel.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -10)
        ])
        
        // Animate in
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1
        }, completion: { _ in
            // Animate out after duration
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                toastView.alpha = 0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        })
    }
    
    // MARK: - Private Methods
    private func styleAlert(_ alertController: UIAlertController, type: AlertType) {
        // Add icon or styling based on type if needed
        switch type {
        case .success:
            // Could add custom styling for success alerts
            break
        case .error:
            // Could add custom styling for error alerts
            break
        case .warning:
            // Could add custom styling for warning alerts
            break
        case .info:
            // Could add custom styling for info alerts
            break
        }
    }
    
    private func getBackgroundColor(for type: AlertType) -> UIColor {
        switch type {
        case .success:
            return .systemGreen
        case .error:
            return .systemRed
        case .warning:
            return .systemOrange
        case .info:
            return .systemBlue
        }
    }
}
