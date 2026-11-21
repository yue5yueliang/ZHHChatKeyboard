//
//  SceneDelegate.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// Scene 生命周期代理：组装入口列表
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let viewModel = HomeViewModel()
        let root = HomeViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: root)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}
