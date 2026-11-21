//
//  XHSChatViewModel.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/20/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 胶囊 · 语音在左 Demo 状态
final class XHSChatViewModel {

    var tipText: String = "capsuleLeading：一体胶囊；上方快捷短语；可开关回复条"

    var showReply: Bool = false
    var showQuickReply: Bool = true

    let quickReplyItems: [XHSQuickReplyBarView.Item] = [
        .init(emoji: "👋", text: "hello"),
        .init(emoji: "🥰", text: "谢谢宝"),
        .init(emoji: "😮", text: "呃"),
        .init(emoji: "👀", text: "在干嘛"),
        .init(emoji: "👍", text: "好的"),
        .init(emoji: "🌙", text: "晚安")
    ]
}
