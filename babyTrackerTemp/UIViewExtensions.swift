import UIKit

/// UIView擴展
extension UIView {
    /// 添加圓角
    /// - Parameter radius: 圓角半徑
    func addCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
    
    /// 添加邊框
    /// - Parameters:
    ///   - width: 邊框寬度
    ///   - color: 邊框顏色
    func addBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    /// 添加陰影
    /// - Parameters:
    ///   - color: 陰影顏色
    ///   - opacity: 陰影不透明度
    ///   - offset: 陰影偏移
    ///   - radius: 陰影半徑
    func addShadow(color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    /// 添加漸變背景
    /// - Parameters:
    ///   - colors: 顏色數組
    ///   - startPoint: 起始點
    ///   - endPoint: 結束點
    func addGradientBackground(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    /// 設置圓形
    func makeCircular() {
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        layer.masksToBounds = true
    }
    
    /// 添加點擊手勢
    /// - Parameter target: 目標
    /// - Parameter action: 動作
    func addTapGesture(target: Any, action: Selector) {
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)
    }
    
    /// 從Nib加載視圖
    /// - Returns: 視圖
    class func fromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    
    /// 添加子視圖並填充
    /// - Parameter view: 子視圖
    func addSubviewAndFill(_ view: UIView) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    /// 設置圓角（指定角）
    /// - Parameters:
    ///   - corners: 圓角位置
    ///   - radius: 圓角半徑
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    /// 抖動動畫
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
    
    /// 脈動動畫
    func pulse() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.3
        pulse.fromValue = 0.95
        pulse.toValue = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.5
        pulse.damping = 1.0
        
        layer.add(pulse, forKey: "pulse")
    }
    
    /// 淡入動畫
    /// - Parameter duration: 持續時間
    func fadeIn(duration: TimeInterval = 0.3) {
        alpha = 0
        isHidden = false
        
        UIView.animate(withDuration: duration) {
            self.alpha = 1
        }
    }
    
    /// 淡出動畫
    /// - Parameter duration: 持續時間
    func fadeOut(duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
        }
    }
}
