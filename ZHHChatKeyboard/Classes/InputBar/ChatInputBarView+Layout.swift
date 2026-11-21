//
//  ChatInputBarView+Layout.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 布局辅助（回复 / 上方配件 / 胶囊 / 贴底）

extension ChatInputBarView {

    /// 按增量调整输入容器高度，并同步录音区与回复条位置
    func resetTextViewHeight(by delta: CGFloat) {
        var containerFrame = textContainerView.frame
        containerFrame.size.height += delta
        textContainerView.frame = containerFrame
        // 容器上下外边距固定；TextView 随容器同步增减高度
        layoutInputTextViewInContainer()
        syncAccessoryViewsWithTextContainer()
        // 输入变高后，下方回复条跟着下移
        layoutReplyViewFrame()
    }

    /// 回复条贴在输入区下方：普通样式对齐 `textContainerView`；胶囊内左右与两侧开关按钮外缘对齐（不是再缩 6）
    func layoutReplyViewFrame() {
        guard let replyView, let margins = replyViewMargins else { return }
        let height = max(replyView.bounds.height, replyView.frame.height)
        let yBase = textContainerView.frame.maxY + margins.top
        if let capsuleView, replyView.superview === capsuleView {
            let fallbackInset = horizontalPadding + capsuleInnerPadding
            // 仅左侧语音才作为回复条左锚；右侧语音跟表情 / + 一起作右缘
            let leading = (voiceButtonPlacement == .leading ? voiceSwitchButton?.frame.minX : nil) ?? fallbackInset
            let trailing = [extendSwitchButton, emotionSwitchButton, rightSendButton, voiceButtonPlacement == .trailing ? voiceSwitchButton : nil]
                .compactMap { $0?.frame.maxX }.max() ?? (capsuleView.bounds.width - fallbackInset)
            // 胶囊内：左右对齐两侧按钮外缘
            replyView.frame = CGRect(x: leading, y: yBase, width: max(0, trailing - leading), height: height)
        } else {
            // 普通样式：与输入圆角容器同宽同 X
            let container = textContainerView!
            replyView.frame = CGRect(x: container.frame.minX, y: yBase, width: container.frame.width, height: height)
        }
    }

    /// 上方配件铺满条宽（左右可带安全区边距）
    func layoutAboveBarFrame() {
        guard let aboveBarView, let margins = aboveBarMargins else { return }
        let safe = safeAreaInsetsOrWindow()
        let height = max(aboveBarView.bounds.height, aboveBarView.frame.height)
        // 横铺满安全区，顶边 = marginTop
        aboveBarView.frame = CGRect(x: safe.left, y: margins.top, width: bounds.width - safe.left - safe.right, height: height)
    }

    /// 是否已把输入控件嵌进胶囊（坐标相对胶囊）
    var isInputChromeEmbeddedInCapsule: Bool {
        guard let capsuleView, let textContainerView else { return false }
        return textContainerView.superview === capsuleView
    }

    /// 将语音 / 表情 / 输入框等挪进胶囊，frame 转成胶囊内坐标
    func embedInputChromeInCapsule() {
        guard let capsuleView else { return }

        // 步骤 1：把条坐标下的控件 re-parent 到胶囊，frame 转局部坐标
        let candidates: [UIView?] = [
            voiceSwitchButton, emotionSwitchButton, extendSwitchButton, rightSendButton,
            textContainerView, recordCenterView, centerContentView, inputInsetRightView, replyView
        ]
        for view in candidates {
            guard let view, view.superview !== capsuleView else { continue }
            let frameInBar = view.convert(view.bounds, to: self)
            let local = CGRect(x: frameInBar.minX - capsuleView.frame.minX, y: frameInBar.minY - capsuleView.frame.minY, width: frameInBar.width, height: frameInBar.height)
            capsuleView.addSubview(view)
            view.frame = local
        }

        // 步骤 2：按钮加 flexibleTopMargin 随胶囊增高贴底；输入容器不加，靠顶向下延伸
        [voiceSwitchButton, emotionSwitchButton, extendSwitchButton, rightSendButton]
            .compactMap { $0 }
            .forEach { button in
                var mask = button.autoresizingMask
                mask.insert(.flexibleTopMargin)
                button.autoresizingMask = mask
            }
        var textMask = textContainerView.autoresizingMask
        textMask.remove(.flexibleTopMargin)
        textContainerView.autoresizingMask = textMask
    }

    /// 胶囊：底边固定离条 `capsuleVerticalInset`；无上方条时顶边同值；有上方条时顶边 = contentYOffset（即其 marginBottom）
    func layoutCapsuleChrome() {
        guard let capsuleView else { return }

        // 步骤 1：水平铺满安全区，左右各留 capsuleHorizontalInset
        let safe = safeAreaInsetsOrWindow()
        let x = safe.left + capsuleHorizontalInset
        let w = bounds.width - safe.left - safe.right - capsuleHorizontalInset * 2
        let minH = capsuleDefaultHeight
        let outer = capsuleVerticalInset

        // 步骤 2：高度只由输入区 + 回复撑开（不把贴底按钮算进 bottom，避免缩高后胶囊卡死）
        let h: CGFloat
        if isInputChromeEmbeddedInCapsule {
            var bottom = minH
            if let text = textContainerView {
                bottom = max(bottom, text.frame.maxY + capsuleTextBottomInset)
            }
            if let reply = replyView, reply.superview === capsuleView, replyOccupiedHeight > 0.5 {
                let replyBottomPad = replyViewMargins?.bottom ?? capsuleButtonBottomInset
                bottom = max(bottom, reply.frame.maxY + replyBottomPad)
            }
            h = bottom
        } else {
            let topAnchor = aboveOccupiedHeight > 0.5 ? contentYOffset : outer
            if let text = textContainerView {
                h = max(text.frame.maxY - topAnchor + capsuleTextBottomInset, minH)
            } else {
                h = minH
            }
        }

        // 步骤 3：贴条底 outer 放置；上方配件始终叠在胶囊之上
        let y = bounds.height - outer - h
        capsuleView.frame = CGRect(x: x, y: max(0, y), width: max(0, w), height: h)
        capsuleView.layer.cornerRadius = capsuleCornerRadius
        sendSubviewToBack(capsuleView)
        if let aboveBarView {
            bringSubviewToFront(aboveBarView)
        }
    }

    /// 开关按钮钉在输入行底（胶囊内 bottom-2；普通样式内容区 bottom-verticalPadding）
    func pinSwitchButtonsToInputRowBottom() {
        if isInputChromeEmbeddedInCapsule {
            // 胶囊内：默认贴胶囊底 −2；有回复时跟输入底对齐，避免按钮掉进回复区
            let capsuleH = capsuleView?.bounds.height ?? capsuleDefaultHeight
            let buttonsY = max(capsuleButtonBottomInset, capsuleH - capsuleButtonBottomInset - switchButtonWidth)
            let y: CGFloat
            if replyOccupiedHeight > 0.5, let text = textContainerView {
                y = max(capsuleButtonBottomInset, text.frame.maxY - switchButtonWidth + (capsuleTextBottomInset - capsuleButtonBottomInset))
            } else {
                y = buttonsY
            }
            moveOriginY(y, view: voiceSwitchButton)
            moveOriginY(y, view: emotionSwitchButton)
            moveOriginY(y, view: extendSwitchButton)
            alignRightSendButtonToTextContainer()
            return
        }

        // 普通样式：在「内容区」内按 verticalPadding 贴底
        let contentHeight = max(contentMinHeight, bounds.height - aboveOccupiedHeight - replyOccupiedHeight)
        let buttonsY = contentYOffset + switchButtonsOriginY(in: contentHeight)
        moveOriginY(buttonsY, view: voiceSwitchButton)
        moveOriginY(buttonsY, view: emotionSwitchButton)
        moveOriginY(buttonsY, view: extendSwitchButton)
        alignRightSendButtonToTextContainer()
    }

    /// 上方配件显隐时下移 / 上移输入区：胶囊模式只挪胶囊整体
    func offsetInputContentY(by delta: CGFloat) {
        guard abs(delta) > 0.5 else { return }
        if let capsuleView, isInputChromeEmbeddedInCapsule {
            // 胶囊已内嵌：整体上移/下移灰底即可
            var frame = capsuleView.frame
            frame.origin.y += delta
            capsuleView.frame = frame
            return
        }
        // 普通样式：输入行各子视图统一改 origin.y
        [voiceSwitchButton, emotionSwitchButton, extendSwitchButton, rightSendButton,
         textContainerView, recordCenterView, centerContentView, inputInsetRightView, replyView]
            .compactMap { $0 }
            .forEach { view in
                var frame = view.frame
                frame.origin.y += delta
                view.frame = frame
            }
    }

    /// 录音区 / 中心插槽 / inset 右视图跟输入容器同步
    func syncAccessoryViewsWithTextContainer() {
        let containerFrame = textContainerView.frame
        // 录音盖住输入区，高与 Y 跟容器
        recordCenterView?.frame.size.height = containerFrame.height
        recordCenterView?.frame.origin.y = containerFrame.origin.y
        centerContentView?.frame.size.height = containerFrame.height
        centerContentView?.frame.origin.y = containerFrame.origin.y
        // 容器右侧小视图垂直居中
        if let inset = inputInsetRightView {
            inset.frame.origin.y = containerFrame.minY + (containerFrame.height - inset.frame.height) / 2
        }
    }

    /// TextView 相对容器上下各留 `ChatInputBarView.textContainerVerticalMargin`
    func layoutInputTextViewInContainer() {
        let margin = ChatInputBarView.textContainerVerticalMargin
        // 左右贴容器，上下各扣 margin
        inputTextView.frame = CGRect(x: 0, y: margin, width: textContainerView.bounds.width, height: max(0, textContainerView.bounds.height - margin * 2))
    }

    /// 开关按钮相对「内容区」底部的 Y（贴底；单行时等于 `verticalPadding`）
    /// - Parameters:
    ///   - contentHeight: 当前内容区高度（已扣上方配件 / 回复占位）
    ///   - buttonHeight: 非零时用自定义按钮高，否则 `switchButtonWidth`
    func switchButtonsOriginY(in contentHeight: CGFloat, buttonHeight: CGFloat = 0) -> CGFloat {
        let height = buttonHeight > 0 ? buttonHeight : switchButtonWidth
        return contentHeight - verticalPadding - height
    }

    /// 回复条 / 上方配件改变底边含义时纠正按钮；文本增减高走 `pinSwitchButtonsToInputRowBottom`
    func relayoutBottomAlignedButtons() {
        pinSwitchButtonsToInputRowBottom()
    }

    /// 右侧发送按钮与 `textContainerView` 底部对齐
    func alignRightSendButtonToTextContainer() {
        guard let rightSendButton, textContainerView != nil else { return }
        // 发送钮底与输入圆角容器底齐平
        moveOriginY(textContainerView.frame.maxY - rightSendButton.frame.height, view: rightSendButton)
    }

    /// TextView 总高度（含内部 inset）
    func textViewContentHeight() -> CGFloat {
        max(textViewContentMinHeight, ceil(inputTextView.sizeThatFits(inputTextView.frame.size).height))
    }

    /// 仅改子视图 `origin.y`（保留宽高与 x）
    private func moveOriginY(_ y: CGFloat, view: UIView?) {
        guard let view else { return }
        var frame = view.frame
        frame.origin.y = y
        view.frame = frame
    }

    /// 取当前 window 安全区；无 window 时退回 keyWindow（见 `ChatKeyboardCommon`）
    func safeAreaInsetsOrWindow() -> UIEdgeInsets {
        ChatKeyboardCommon.safeAreaInsets(for: self)
    }
}