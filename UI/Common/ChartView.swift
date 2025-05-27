import UIKit

/// 通用圖表視圖
class ChartView: UIView {
    // MARK: - 屬性
    
    /// 標題標籤
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 圖表容器視圖
    private let chartContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 無數據標籤
    private let noDataLabel: UILabel = {
        let label = UILabel()
        label.text = "暫無數據"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter title: 圖表標題
    init(title: String) {
        super.init(frame: .zero)
        
        titleLabel.text = title
        
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
        addSubview(titleLabel)
        addSubview(chartContainerView)
        addSubview(noDataLabel)
        
        // 設置約束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            chartContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            chartContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            noDataLabel.centerXAnchor.constraint(equalTo: chartContainerView.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: chartContainerView.centerYAnchor)
        ])
    }
    
    // MARK: - 公共方法
    
    /// 更新標題
    /// - Parameter title: 標題
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
    
    /// 顯示無數據狀態
    /// - Parameter message: 無數據消息
    func showNoData(message: String = "暫無數據") {
        noDataLabel.text = message
        noDataLabel.isHidden = false
    }
    
    /// 隱藏無數據狀態
    func hideNoData() {
        noDataLabel.isHidden = true
    }
    
    /// 清除圖表
    func clearChart() {
        // 移除所有圖表子視圖
        chartContainerView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    /// 獲取圖表容器視圖
    /// - Returns: 圖表容器視圖
    func getChartContainerView() -> UIView {
        return chartContainerView
    }
    
    /// 添加子視圖到圖表容器
    /// - Parameter view: 子視圖
    func addChartSubview(_ view: UIView) {
        chartContainerView.addSubview(view)
    }
}
