//
//  ChatInputBarView+Actions.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 按钮点击（语音 / 表情 / 扩展）

extension ChatInputBarView {

    /// 语音 ↔ 键盘；切入语音时暂存输入富文本
    @objc func onVoiceSwitchButtonClick(_ sender: UIButton) {
        // 本钮选中；表情 / + 取消选中（避免多面板叠态）
        sender.isSelected.toggle()
        emotionSwitchButton?.isSelected = false
        extendSwitchButton?.isSelected = false

        if sender.isSelected {
            // 进入语音：暂存富文本并清空，KVO 收单行，收键盘
            inputedAttributedText = inputTextView.attributedText
            inputTextView.text = nil
            textViewDidChange(inputTextView)
            inputTextView.resignFirstResponder()
        } else {
            // 切回输入：恢复暂存、刷新发送钮，弹键盘
            restoreInputTextIfNeeded()
            inputTextView.becomeFirstResponder()
        }

        // 录音盖层与输入容器 alpha 互斥
        UIView.animate(withDuration: 0.2) {
            self.recordCenterView?.alpha = sender.isSelected ? 1 : 0
            self.textContainerView.alpha = sender.isSelected ? 0 : 1
        }
        delegate?.chatInputBarView(self, onVoiceSwitchButtonClick: sender)
    }

    /// 表情 ↔ 键盘；若从语音模式切入则先恢复暂存输入
    @objc func onEmotionSwitchButtonClick(_ sender: UIButton) {
        sender.isSelected.toggle()
        let leavingVoice = voiceSwitchButton?.isSelected == true
        voiceSwitchButton?.isSelected = false
        extendSwitchButton?.isSelected = false

        // 从语音切表情：先恢复暂存文字，再显输入区
        if leavingVoice {
            restoreInputTextIfNeeded()
        }

        UIView.animate(withDuration: 0.2) {
            self.recordCenterView?.alpha = 0
            self.textContainerView.alpha = 1
        }
        delegate?.chatInputBarView(self, onEmotionButtonClick: sender)
    }

    /// 扩展「+」；从语音模式切出时恢复输入并显示文本容器
    @objc func onExtendSwitchButtonClick(_ sender: UIButton) {
        sender.isSelected.toggle()
        emotionSwitchButton?.isSelected = false

        // 语音模式下点 +：关语音、恢复输入、显文本容器
        if voiceSwitchButton?.isSelected == true {
            voiceSwitchButton?.isSelected = false
            restoreInputTextIfNeeded()
            UIView.animate(withDuration: 0.2) {
                self.recordCenterView?.alpha = 0
                self.textContainerView.alpha = 1
            }
        }

        delegate?.chatInputBarView(self, onExtendButtonClick: sender)
    }

    /// 从语音模式切回输入时恢复暂存内容
    func restoreInputTextIfNeeded() {
        guard let stashed = inputedAttributedText else { return }
        // 写回富文本、刷新发送/+ 互斥，清空暂存
        inputTextView.attributedText = stashed
        textViewDidChange(inputTextView)
        inputedAttributedText = nil
    }
}