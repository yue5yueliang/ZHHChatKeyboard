//
//  ChatKeyboardColor.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/18.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 库默认聊天色板（Common 模块，默认灰，含 Light / Dark）。
///
/// 用法说明：
/// - 对外只暴露 `UIColor`，不暴露 Asset 资源名
/// - 「Asset 默认色」优先从 `ChatKeyboardBundle` 的 Color Set 读取，缺失时用代码兜底（保证无资源也能跑）
/// - 「代码色板」无独立 colorset，直接用代码定义（发送绿、角标红等）
/// - 业务覆盖色请走 `ChatInputBarConfiguration` / 各面板的颜色属性，不要依赖本文件内部实现
public enum ChatKeyboardColor {

    // MARK: - Asset 默认色（含 Light / Dark）

    /// 输入条整条背景（条背景灰）
    public static var barBackground: UIColor { named("barBackground", light: 0.965, dark: rgb(0.114, 0.114, 0.110)) }
    /// 输入条顶部分隔线 / 面板与输入条之间的顶线
    public static var barSeparator: UIColor { named("barSeparator", light: 0.875, dark: rgb(0.208, 0.204, 0.192)) }
    /// 主文字色（输入文字等）
    public static var primaryText: UIColor { named("primaryText", light: 0, dark: 0.769) }
    /// 输入框 / 扩展入口卡片等填充白底
    public static var inputFill: UIColor { named("inputFill", light: 1, dark: rgb(0.145, 0.153, 0.153)) }
    /// 「按住说话」按钮标题色
    public static var recordTitle: UIColor { named("recordTitle", light: 0, dark: 0.958) }
    /// 次要文字 / 图标色（扩展入口标题、删除按钮 tint 等）
    public static var secondaryText: UIColor { named("secondaryText", light: 0.357, dark: 0.769) }
    /// 表情面板 / 扩展面板内容区背景
    public static var boardBackground: UIColor { named("boardBackground", light: 0.945, dark: 0.122) }

    // MARK: - 代码色板（无独立 Color Set）

    /// 表情面板「发送」按钮正常背景（发送绿）
    public static var sendButton: UIColor {
        UIColor(red: 32 / 255, green: 191 / 255, blue: 100 / 255, alpha: 1)
    }
    /// 表情面板「发送」按钮按下背景
    public static var sendButtonHighlight: UIColor {
        UIColor(red: 26 / 255, green: 160 / 255, blue: 84 / 255, alpha: 1)
    }

    /// 表情面板「删除」按钮按下背景
    public static var deleteButtonHighlight: UIColor {
        dynamic(light: UIColor(red: 229 / 255, green: 229 / 255, blue: 229 / 255, alpha: 1),
                dark: UIColor(white: 0.25, alpha: 1))
    }

    /// 表情组 Tab 选中态背景
    public static var tabSelectedFill: UIColor {
        dynamic(light: UIColor(white: 0, alpha: 0.06), dark: UIColor(white: 1, alpha: 0.12))
    }

    /// 扩展入口卡片按下背景
    public static var itemCardHighlight: UIColor {
        dynamic(light: UIColor(white: 0.92, alpha: 1), dark: UIColor(white: 0.22, alpha: 1))
    }

    /// 扩展面板 PageControl 当前页指示点
    public static var pageIndicatorCurrent: UIColor {
        dynamic(light: UIColor(white: 0.28, alpha: 1), dark: UIColor(white: 0.75, alpha: 1))
    }
    /// 扩展面板 PageControl 未选中指示点
    public static var pageIndicator: UIColor {
        dynamic(light: UIColor(white: 0.75, alpha: 1), dark: UIColor(white: 0.35, alpha: 1))
    }

    /// 扩展入口角标红
    public static var badge: UIColor {
        UIColor(red: 250 / 255, green: 81 / 255, blue: 81 / 255, alpha: 1)
    }

    // MARK: - 私有加载 / 兜底

    /// 灰阶 Light + 灰阶 Dark 的命名色快捷入口
    private static func named(_ name: String, light: CGFloat, dark: CGFloat) -> UIColor {
        named(name, light: UIColor(white: light, alpha: 1), dark: UIColor(white: dark, alpha: 1))
    }

    /// 灰阶 Light + 任意 Dark 的命名色快捷入口（Dark 需非灰阶时用）
    private static func named(_ name: String, light: CGFloat, dark: UIColor) -> UIColor {
        named(name, light: UIColor(white: light, alpha: 1), dark: dark)
    }

    /// 从资源 Bundle 读 Color Set；读不到则用 Light/Dark 动态色兜底
    private static func named(_ name: String, light: UIColor, dark: UIColor) -> UIColor {
        if let color = UIColor(named: name, in: ChatKeyboardBundle.bundle, compatibleWith: nil) {
            return color
        }
        return dynamic(light: light, dark: dark)
    }

    /// 按当前 `userInterfaceStyle` 在 Light / Dark 间切换
    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }

    /// 0～1 分量的 RGB 便捷构造
    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
        UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}
