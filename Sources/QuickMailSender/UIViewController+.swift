//
//  File.swift
//  QuickMailSender
//
//  Created by Corotata on 2024/9/30.
//

import Foundation

#if canImport(UIKit)

import UIKit
extension UIViewController {
    
    // 获取最顶层的视图控制器
    static func topMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return getTopViewController(rootViewController)
    }

    // 私有方法，用于递归查找顶层视图控制器
    private static func getTopViewController(_ rootViewController: UIViewController) -> UIViewController {
        if let navController = rootViewController as? UINavigationController {
            // 递归找到导航栈最顶层的视图控制器
            return getTopViewController(navController.visibleViewController ?? navController)
        } else if let tabBarController = rootViewController as? UITabBarController {
            // 递归找到 TabBar 选中的视图控制器
            return getTopViewController(tabBarController.selectedViewController ?? tabBarController)
        } else if let presentedController = rootViewController.presentedViewController {
            // 递归找到被 present 出来的视图控制器
            return getTopViewController(presentedController)
        }
        
        // 返回最顶层的视图控制器
        return rootViewController
    }
}

#endif
