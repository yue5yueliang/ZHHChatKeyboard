//
//  ChatInputBarViewDelegate.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 输入条事件回调（默认空实现，按需覆写）
public protocol ChatInputBarViewDelegate: AnyObject {
    /// 输入框即将开始编辑
    func chatInputBarView(_ bar: ChatInputBarView, inputTextViewShouldBeginEditing textView: UITextView)
    /// 输入框已开始编辑
    func chatInputBarView(_ bar: ChatInputBarView, inputTextViewDidBeginEditing textView: UITextView)
    /// 输入内容变化（含表情插入）
    func chatInputBarView(_ bar: ChatInputBarView, textViewDidChange textView: UITextView)

    /// 输入区因换行 / 发送清空导致高度变化；`becauseSendText` 为 true 时动画可更短
    func chatInputBarView(_ bar: ChatInputBarView, inputTextView textView: UITextView, heightDidChange changeValue: CGFloat, becauseSendText: Bool)
    /// 回复条显隐导致整条高度变化；`changeValue` 为高度增量（隐藏时为负）
    func chatInputBarView(_ bar: ChatInputBarView, heightDidChangeBecauseReply changeValue: CGFloat, showReplyView: Bool)
    /// 上方配件（如快捷短语）显隐导致整条高度变化
    func chatInputBarView(_ bar: ChatInputBarView, heightDidChangeBecauseAboveBar changeValue: CGFloat, showAboveBar: Bool)

    /// 点击语音 / 键盘切换按钮
    func chatInputBarView(_ bar: ChatInputBarView, onVoiceSwitchButtonClick button: UIButton)
    /// 键盘回车发送（需 `keyboardSendEnabled`）；`inputNormalText` 已还原表情纯文本
    func chatInputBarView(_ bar: ChatInputBarView, onKeyboardSendClick inputNormalText: String)
    /// 点击扩展「+」按钮（通常切到扩展面板）
    func chatInputBarView(_ bar: ChatInputBarView, onExtendButtonClick button: UIButton)
    /// 点击表情 / 键盘切换按钮
    func chatInputBarView(_ bar: ChatInputBarView, onEmotionButtonClick button: UIButton)
    /// 右侧发送按钮将显示或隐藏（有字显示、无字隐藏时）
    func chatInputBarView(_ bar: ChatInputBarView, rightSendButtonWillSwitch buttonWillAppear: Bool)
}

/// 委托默认空实现，按需覆写单个回调即可
public extension ChatInputBarViewDelegate {
    func chatInputBarView(_ bar: ChatInputBarView, inputTextViewShouldBeginEditing textView: UITextView) {}
    func chatInputBarView(_ bar: ChatInputBarView, inputTextViewDidBeginEditing textView: UITextView) {}
    func chatInputBarView(_ bar: ChatInputBarView, textViewDidChange textView: UITextView) {}

    func chatInputBarView(_ bar: ChatInputBarView, inputTextView textView: UITextView, heightDidChange changeValue: CGFloat, becauseSendText: Bool) {}
    func chatInputBarView(_ bar: ChatInputBarView, heightDidChangeBecauseReply changeValue: CGFloat, showReplyView: Bool) {}
    func chatInputBarView(_ bar: ChatInputBarView, heightDidChangeBecauseAboveBar changeValue: CGFloat, showAboveBar: Bool) {}

    func chatInputBarView(_ bar: ChatInputBarView, onVoiceSwitchButtonClick button: UIButton) {}
    func chatInputBarView(_ bar: ChatInputBarView, onKeyboardSendClick inputNormalText: String) {}
    func chatInputBarView(_ bar: ChatInputBarView, onExtendButtonClick button: UIButton) {}
    func chatInputBarView(_ bar: ChatInputBarView, onEmotionButtonClick button: UIButton) {}
    func chatInputBarView(_ bar: ChatInputBarView, rightSendButtonWillSwitch buttonWillAppear: Bool) {}
}