import UIKit

/// 通用卡片視圖
class CardView: UIView {
    // MARK: - 屬性
    
    /// 內容視圖
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI設置
    
    /// 設置UI
    private func setupUI() {
        // 添加子視圖
        addSubview(contentView)
        
        // 設置約束
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - 公共方法
    
    /// 添加子視圖到內容視圖
    /// - Parameter view: 子視圖
    func addContentSubview(_ view: UIView) {
        contentView.addSubview(view)
    }
    
    /// 獲取內容視圖
    /// - Returns: 內容視圖
    func getContentView() -> UIView {
        return contentView
    }
    
    /// 設置卡片邊距
    /// - Parameter insets: 邊距
    func setContentInsets(_ insets: UIEdgeInsets) {
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
    
    /// 設置陰影
    /// - Parameters:
    ///   - color: 陰影顏色
    ///   - offset: 陰影偏移
    ///   - radius: 陰影半徑
    ///   - opacity: 陰影不透明度
    func setShadow(color: UIColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        contentView.layer.shadowColor = color.cgColor
        contentView.layer.shadowOffset = offset
        contentView.layer.shadowRadius = radius
        contentView.layer.shadowOpacity = opacity
    }
    
    /// 設置圓角
    /// - Parameter radius: 圓角半徑
    func setCornerRadius(_ radius: CGFloat) {
        contentView.layer.cornerRadius = radius
    }
    
    /// 設置背景顏色
    /// - Parameter color: 背景顏色
    func setCardBackgroundColor(_ color: UIColor) {
        contentView.backgroundColor = color
    }
}
