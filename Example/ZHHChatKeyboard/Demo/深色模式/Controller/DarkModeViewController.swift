//
//  DarkModeViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 深色模式 Demo：在普通常驻页上切换浅色 / 深色外观
final class DarkModeViewController: CommonViewController {

    /// 页面文案
    private let darkViewModel = DarkModeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = darkViewModel.titleText
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "切换外观",
            style: .plain,
            target: self,
            action: #selector(toggleStyle)
        )
    }

    /// 在浅色 / 深色之间切换
    @objc private func toggleStyle() {
        overrideUserInterfaceStyle = overrideUserInterfaceStyle == .dark ? .light : .dark
    }
}
