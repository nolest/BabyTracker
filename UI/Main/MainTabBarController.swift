import UIKit

/// 主標籤欄控制器
class MainTabBarController: UITabBarController {
    // MARK: - 屬性
    
    /// 依賴容器
    private let container: DependencyContainer
    
    // MARK: - 初始化
    
    /// 初始化方法
    /// - Parameter container: 依賴容器
    init(container: DependencyContainer = DependencyContainer.shared) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設置視圖控制器
        setupViewControllers()
        
        // 設置外觀
        setupAppearance()
    }
    
    // MARK: - 私有方法
    
    /// 設置視圖控制器
    private func setupViewControllers() {
        // 創建視圖控制器
        let homeVC = createHomeViewController()
        let recordsVC = createRecordsViewController()
        let statsVC = createStatsViewController()
        let settingsVC = createSettingsViewController()
        
        // 設置標籤欄項目
        viewControllers = [
            homeVC,
            recordsVC,
            statsVC,
            settingsVC
        ]
    }
    
    /// 設置外觀
    private func setupAppearance() {
        // 設置標籤欄外觀
        tabBar.tintColor = UIColor(red: 0.0, green: 0.6, blue: 0.8, alpha: 1.0)
        tabBar.unselectedItemTintColor = .gray
        
        // 設置標籤欄背景
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    /// 創建首頁視圖控制器
    /// - Returns: 導航控制器
    private func createHomeViewController() -> UINavigationController {
        // 創建視圖模型
        let viewModel = HomeViewModel()
        
        // 創建視圖控制器
        let viewController = HomeViewController(viewModel: viewModel)
        
        // 創建導航控制器
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // 設置標籤欄項目
        navigationController.tabBarItem = UITabBarItem(
            title: "今日",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        return navigationController
    }
    
    /// 創建記錄視圖控制器
    /// - Returns: 導航控制器
    private func createRecordsViewController() -> UINavigationController {
        // 創建視圖控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.title = "記錄"
        
        // 創建導航控制器
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // 設置標籤欄項目
        navigationController.tabBarItem = UITabBarItem(
            title: "記錄",
            image: UIImage(systemName: "list.bullet"),
            selectedImage: UIImage(systemName: "list.bullet")
        )
        
        return navigationController
    }
    
    /// 創建統計視圖控制器
    /// - Returns: 導航控制器
    private func createStatsViewController() -> UINavigationController {
        // 創建視圖控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.title = "統計"
        
        // 創建導航控制器
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // 設置標籤欄項目
        navigationController.tabBarItem = UITabBarItem(
            title: "統計",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )
        
        return navigationController
    }
    
    /// 創建設置視圖控制器
    /// - Returns: 導航控制器
    private func createSettingsViewController() -> UINavigationController {
        // 創建視圖控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.title = "設置"
        
        // 創建導航控制器
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // 設置標籤欄項目
        navigationController.tabBarItem = UITabBarItem(
            title: "設置",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear")
        )
        
        return navigationController
    }
}
