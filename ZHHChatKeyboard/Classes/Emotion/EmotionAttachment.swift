//
//  EmotionAttachment.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 表情富文本附件（Emotion 模块）。
///
/// 职责：在 `NSAttributedString` 中占位一个 attachment 字符，同时记住原始 key。
/// 用法：由 `EmotionHelper` 创建并写入 `ChatInputTextView`；导出 `normalText` 时
/// 将附件还原为 `displayText`（如 `[微笑]`），便于发送与存储。
open class EmotionAttachment: NSTextAttachment {

    // MARK: - 属性

    /// 对应的纯文本 key，如 `[微笑]`；导出 `normalText` 时写回字符串
    public var displayText: String?
}