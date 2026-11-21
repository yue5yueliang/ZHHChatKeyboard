//
//  ChatInputBarView+TextView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - UITextViewDelegate

extension ChatInputBarView: UITextViewDelegate {

    /// 开始编辑前通知业务；返回 true 允许编辑
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.chatInputBarView(self, inputTextViewShouldBeginEditing: textView)

        // 点进输入框：各开关回到非选中（键盘态）
        emotionSwitchButton?.isSelected = false
        voiceSwitchButton?.isSelected = false
        extendSwitchButton?.isSelected = false
        return true
    }

    /// 已开始编辑：补齐 `previousTextViewContentHeight` 初值并回调
    public func textViewDidBeginEditing(_ textView: UITextView) {
        // 首获焦时补 KVO 基线，避免第一次增高 delta 异常
        if previousTextViewContentHeight == 0 {
            previousTextViewContentHeight = textViewContentHeight()
        }
        delegate?.chatInputBarView(self, inputTextViewDidBeginEditing: textView)
    }

    /// 文本变化：有字显示发送、隐藏「+」；无字相反，并通知 delegate
    public func textViewDidChange(_ textView: UITextView) {
        // 有字：显示发送、隐藏「+」；无字：相反（仅两者都配置时互斥）
        if let rightSendButton, let extendSwitchButton {
            let empty = (textView.text ?? "").isEmpty
            if rightSendButton.isHidden != empty {
                delegate?.chatInputBarView(self, rightSendButtonWillSwitch: !empty)
                rightSendButton.isHidden = empty
                extendSwitchButton.isHidden = !empty
            }
        }

        delegate?.chatInputBarView(self, textViewDidChange: textView)
    }

    /// 拦截回车：开启 `keyboardSendEnabled` 时走发送回调，不插入换行
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if keyboardSendEnabled && text == "\n" {
            // 回车 → 纯文本发送，不插入换行符
            delegate?.chatInputBarView(self, onKeyboardSendClick: textView.normalText)
            return false
        }
        return true
    }
}

// MARK: - KVO（contentSize → 多行增高 / 发送缩高）

extension ChatInputBarView {

    /// 监听输入框 contentSize，驱动条高变化并回调 `heightDidChange`
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard object as AnyObject? === inputTextView, keyPath == "contentSize" else { return }

        // 步骤 1：量新高度，区分增高 / 缩高，并钳制到最大行高
        let newHeight = textViewContentHeight()
        let shouldShrink = newHeight < previousTextViewContentHeight
        var delta = newHeight - previousTextViewContentHeight
        if !shouldShrink && (previousTextViewContentHeight == textViewContentMaxHeight || (inputTextView.text ?? "").isEmpty) {
            delta = 0
        } else {
            delta = min(delta, textViewContentMaxHeight - previousTextViewContentHeight)
        }

        if delta != 0 {
            let duration = clearInputTextBySendSoon ? heightChangeWhenSendDuration : heightChangeDuration
            UIView.animate(withDuration: duration, animations: { [weak self] in
                guard let self else { return }

                // 步骤 2：缩高先改容器，再改条高；增高先改条高，再改容器（保持底边不动）
                if shouldShrink {
                    self.resetTextViewHeight(by: delta)
                }
                var frame = self.frame
                frame.size.height += delta
                self.frame = frame
                if !shouldShrink {
                    self.resetTextViewHeight(by: delta)
                }

                // 步骤 3：胶囊跟输入走，按钮钉回输入行底，通知业务
                self.layoutCapsuleChrome()
                self.pinSwitchButtonsToInputRowBottom()
                self.delegate?.chatInputBarView(self, inputTextView: self.inputTextView, heightDidChange: delta, becauseSendText: self.clearInputTextBySendSoon)
            })
            previousTextViewContentHeight = min(newHeight, textViewContentMaxHeight)
        }
        clearInputTextBySendSoon = false

        // 步骤 4：已达最大高度时滚 contentOffset，不切 isScrollEnabled（避免首行/光标错位）
        if previousTextViewContentHeight == textViewContentMaxHeight {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self else { return }
                let tv = self.inputTextView!
                let contentH = max(newHeight, ceil(tv.contentSize.height))
                let offsetY = max(0, contentH - tv.bounds.height)
                // 滚到内容底，并保证光标可见
                tv.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
                tv.scrollRangeToVisible(tv.selectedRange)
            }
        }
    }
}