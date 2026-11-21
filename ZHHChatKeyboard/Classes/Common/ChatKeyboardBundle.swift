//
//  ChatKeyboardBundle.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 库内资源 Bundle 定位（图标、色板、PrivacyInfo 等）。
///
/// 职责：在 CocoaPods / SPM / 静态库等多种集成方式下解析 `ZHHChatKeyboard.bundle`。
/// 用法：`ChatKeyboardBundle.bundle` 传给 `UIImage(named:in:compatibleWith:)` 等 API。
/// 找不到具名 bundle 时回退到 `Bundle(for:)` / main，避免图标加载为 nil。
enum ChatKeyboardBundle {

    // MARK: - 公开

    /// 资源 Bundle；找不到具名 bundle 时回退到模块主 Bundle
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        // SPM：编译期注入的 module 资源
        return Bundle.module
        #else
        // CocoaPods / 静态库：在候选 Bundle 内查找 ZHHChatKeyboard.bundle
        let candidates: [Bundle] = [Bundle(for: BundleToken.self), Bundle.main]
        for candidate in candidates {
            if let url = candidate.url(forResource: "ZHHChatKeyboard", withExtension: "bundle"),
               let resource = Bundle(url: url) {
                return resource
            }
        }
        // 兜底：至少回到模块类所在的 Bundle
        return Bundle(for: BundleToken.self)
        #endif
    }
}

// MARK: - 私有

/// 仅用于 `Bundle(for:)` 的锚定类（无业务逻辑）
private final class BundleToken {}
