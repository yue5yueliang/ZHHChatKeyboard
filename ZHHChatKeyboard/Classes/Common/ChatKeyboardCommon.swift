//
//  ChatKeyboardCommon.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/21.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 库内通用几何 / 窗口小工具（Common）：安全区兜底、分隔线高度、像素对齐。
///
/// 只放跨模块重复出现的能力；业务布局语义仍留在各模块。
enum ChatKeyboardCommon {

    // MARK: - 安全区

    /// 当前 keyWindow 的安全区；找不到可用 window 时为 `.zero`
    static var keyWindowSafeAreaInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets }
            .first ?? .zero
    }

    /// 优先 `view.window` 的安全区；尚未入窗时退回 `keyWindowSafeAreaInsets`
    /// - Parameter view: 目标视图（如输入条、宿主容器）
    static func safeAreaInsets(for view: UIView) -> UIEdgeInsets {
        view.window?.safeAreaInsets ?? keyWindowSafeAreaInsets
    }

    // MARK: - 分隔线 / 像素

    /// 物理 1px 分隔线高度（随屏幕 scale 变化）
    static var hairlineHeight: CGFloat { 1 / UIScreen.main.scale }

    /// 按屏幕 scale 向下取整，避免亚像素布局抖动
    /// - Parameter value: 原始长度
    static func pixelRound(_ value: CGFloat) -> CGFloat {
        let scale = UIScreen.main.scale
        return floor(value * scale) / scale
    }
}
