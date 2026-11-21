//
//  CommonViewModel.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 普通常驻输入栏页状态与可调配置
final class CommonViewModel {

    /// 中间提示文案
    var statusText: String = "下方可调输入条配置；点击输入栏切换键盘 / 表情 / 扩展"

    /// 是否显示语音按钮
    var showVoiceButton: Bool = true
    /// 是否显示表情按钮
    var showEmotionButton: Bool = true
    /// 是否显示更多（+）按钮
    var showExtendButton: Bool = true
    /// 是否启用键盘发送（点键盘 return）
    var keyboardSendEnabled: Bool = true
    /// 是否使用右侧独立发送按钮（会与更多按钮互斥显示逻辑）
    var showRightSendButton: Bool = false
    /// 是否在输入框下方显示回复 View（`showReplyView`）
    var showTopCustomView: Bool = false
    /// 是否在 VC 上用高度回调贴红块（不在条上，对齐 QK debugLeftBottomView）
    var showHeightFollowRedBlock: Bool = false
}
