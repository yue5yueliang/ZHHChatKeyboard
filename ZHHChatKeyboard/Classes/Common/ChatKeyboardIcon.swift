//
//  ChatKeyboardIcon.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/18.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 库默认输入条图标（Common 模块）。
///
/// 对外只暴露 `UIImage`；资源名仅作内部实现，从 `ChatKeyboardBundle` 加载。
/// 业务请通过 `ChatInputBarConfiguration` 的 `*Image` 属性覆盖，不要依赖 Asset 文件名。
public enum ChatKeyboardIcon {

    // MARK: - 默认图标

    /// 语音开关（未选中）
    public static var voiceSwitch: UIImage? { named("voiceSwitch") }
    /// 键盘开关（语音 / 表情选中后切回键盘）
    public static var keyboardSwitch: UIImage? { named("keyboardSwitch") }
    /// 表情开关（未选中）
    public static var emotionSwitch: UIImage? { named("emotionSwitch") }
    /// 扩展「+」开关
    public static var extendSwitch: UIImage? { named("extendSwitch") }
    /// 「按住说话」正常态底图
    public static var recordBackground: UIImage? { named("recordBackground") }
    /// 「按住说话」按下态底图
    public static var recordBackgroundPressed: UIImage? { named("recordBackgroundPressed") }

    // MARK: - 私有加载

    /// 从 `ChatKeyboardBundle` 读取模板图；找不到返回 nil（业务可用 Configuration 覆盖）
    /// - Parameter name: Asset 内图片名（仅内部使用，对外勿依赖）
    private static func named(_ name: String) -> UIImage? {
        UIImage(named: name, in: ChatKeyboardBundle.bundle, compatibleWith: nil)
    }
}
