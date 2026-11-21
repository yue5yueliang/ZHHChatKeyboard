//
//  ChatMessage.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 聊天消息模型
struct ChatMessage {

    /// 消息 id
    let id: Int
    /// 纯文本（可含表情占位如 `[微笑]`）
    let text: String
    /// 是否为自己发出
    let isOutgoing: Bool
}
