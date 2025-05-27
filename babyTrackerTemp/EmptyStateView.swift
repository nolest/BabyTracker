import UIKit

/// 通用空狀態視圖
class EmptyStateView: UIView {
    // MARK: - 屬性
    
    /// 圖像視圖
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// 標題標籤
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .darkText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 消息標籤
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 操作按鈕
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// 按鈕操作回調
    private var actionHandler: (() -> Void)?
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - image: 圖像
    ///   - title: 標題
    ///   - message: 消息
    ///   - buttonTitle: 按鈕標題
    ///   - actionHandler: 按鈕操作回調
    init(image: UIImage?, title: String, message: String, buttonTitle: String? = nil, actionHandler: (() -> Void)? = nil) {
        super.init(frame: .zero)
        
        imageView.image = image
        titleLabel.text = title
        messageLabel.text = message
        
        if let buttonTitle = buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            self.actionHandler = actionHandler
        } else {
            actionButton.isHidden = true
        }
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 設置背景顏色
        backgroundColor = .white
        
        // 添加子視圖
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(actionButton)
        
        // 設置約束
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 44),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
        
        // 添加按鈕動作
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - 動作
    
    /// 按鈕點擊
    @objc private func actionButtonTapped() {
        actionHandler?()
    }
    
    // MARK: - 公共方法
    
    /// 更新圖像
    /// - Parameter image: 圖像
    func updateImage(_ image: UIImage?) {
        imageView.image = image
    }
    
    /// 更新標題
    /// - Parameter title: 標題
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
    
    /// 更新消息
    /// - Parameter message: 消息
    func updateMessage(_ message: String) {
        messageLabel.text = message
    }
    
    /// 更新按鈕標題
    /// - Parameter title: 按鈕標題
    func updateButtonTitle(_ title: String?) {
        if let title = title {
            actionButton.setTitle(title, for: .normal)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }
    
    /// 更新按鈕操作
    /// - Parameter handler: 按鈕操作回調
    func updateActionHandler(_ handler: (() -> Void)?) {
        actionHandler = handler
    }
}
