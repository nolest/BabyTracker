import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            // 設置根視圖控制器
            // 這裡使用一個簡單的TabBarController作為示例
            let tabBarController = UITabBarController()
            
            // 創建主頁面
            let homeVC = UIViewController()
            homeVC.view.backgroundColor = .systemBackground
            homeVC.tabBarItem = UITabBarItem(title: "主頁", image: UIImage(systemName: "house"), tag: 0)
            
            // 創建記錄頁面
            let recordVC = UIViewController()
            recordVC.view.backgroundColor = .systemBackground
            recordVC.tabBarItem = UITabBarItem(title: "記錄", image: UIImage(systemName: "plus.circle"), tag: 1)
            
            // 創建分析頁面
            let analysisVC = UIViewController()
            analysisVC.view.backgroundColor = .systemBackground
            analysisVC.tabBarItem = UITabBarItem(title: "分析", image: UIImage(systemName: "chart.bar"), tag: 2)
            
            // 創建設置頁面
            let settingsVC = UIViewController()
            settingsVC.view.backgroundColor = .systemBackground
            settingsVC.tabBarItem = UITabBarItem(title: "設置", image: UIImage(systemName: "gear"), tag: 3)
            
            // 設置TabBarController的視圖控制器
            tabBarController.viewControllers = [homeVC, recordVC, analysisVC, settingsVC]
            
            window.rootViewController = tabBarController
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // 場景斷開連接時調用
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 場景變為活躍狀態時調用
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // 場景即將變為非活躍狀態時調用
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // 場景即將進入前台時調用
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // 場景進入後台時調用
    }
}
