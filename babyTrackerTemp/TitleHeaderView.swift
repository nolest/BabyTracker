import UIKit

/// 通用標題視圖
class TitleHeaderView: UIView {
    // MARK: - 屬性
    
    /// 標題標籤
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .darkText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 副標題標籤
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameters:
    ///   - title: 標題
    ///   - subtitle: 副標題
    init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 添加子視圖
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        // 設置約束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - 公共方法
    
    /// 更新標題
    /// - Parameter title: 標題
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
    
    /// 更新副標題
    /// - Parameter subtitle: 副標題
    func updateSubtitle(_ subtitle: String?) {
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
    }
}
