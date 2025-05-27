import UIKit

/// 啟動畫面視圖控制器
class LaunchScreenViewController: UIViewController {
    // MARK: - 屬性
    
    /// 應用標誌圖像視圖
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// 應用名稱標籤
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "寶寶生活記錄"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 副標題標籤
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "專業版"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 活動指示器
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設置視圖
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 開始動畫
        startAnimation()
    }
    
    // MARK: - 私有方法
    
    /// 設置視圖
    private func setupView() {
        // 設置背景色
        view.backgroundColor = .systemBackground
        
        // 添加子視圖
        view.addSubview(logoImageView)
        view.addSubview(appNameLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(activityIndicator)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 應用標誌圖像視圖
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // 應用名稱標籤
            appNameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            appNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 副標題標籤
            subtitleLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 活動指示器
            activityIndicator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    /// 開始動畫
    private func startAnimation() {
        // 開始活動指示器
        activityIndicator.startAnimating()
        
        // 延遲2秒後轉場到主畫面
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.navigateToMainScreen()
        }
    }
    
    /// 導航到主畫面
    private func navigateToMainScreen() {
        // 創建主標籤欄控制器
        let mainTabBarController = MainTabBarController()
        
        // 設置窗口根視圖控制器
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = mainTabBarController
            }, completion: nil)
        }
    }
}
