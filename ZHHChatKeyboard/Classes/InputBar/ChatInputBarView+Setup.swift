//
//  ChatInputBarView+Setup.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - setup 过程量

/// `setup(with:)` 各步骤之间传递的几何与资源（不持久化）
struct ChatInputBarSetupMetrics {
    /// 是否胶囊风格
    let isCapsule: Bool
    /// 当前风格下内容区最小高度
    let preferredContentH: CGFloat
    /// 开关按钮相对输入行底的 inset
    let buttonBottomInset: CGFloat
    /// 输入容器相对输入行底的 inset
    let textBottomInset: CGFloat
    /// 左侧布局基准（安全区 + 胶囊内边距）
    let leadingBase: CGFloat
    /// 右侧布局基准
    let trailingBase: CGFloat
    /// 输入行底边 Y（条坐标）
    let rowBottom: CGFloat
    /// 开关按钮原点 Y
    let buttonsY: CGFloat

    /// 语音 / 键盘图
    let voiceImage: UIImage?
    let keyboardImage: UIImage?
    let emotionImage: UIImage?
    let extendImage: UIImage?
    let recordNormalImage: UIImage?
    let recordPressedImage: UIImage?

    /// 是否在左侧放语音
    let showLeadingVoice: Bool
    /// 是否在右侧放语音
    let showTrailingVoice: Bool
}

/// 右侧按钮堆叠后得到的输入区水平锚点
struct ChatInputBarSetupHorizontalRange {
    /// 输入容器左缘
    var minX: CGFloat
    /// 右侧控件链最左缘（0 表示右侧无按钮）
    var rightViewsMinX: CGFloat
}

// MARK: - setup 分步

extension ChatInputBarView {

    /// 写入配置字段、补最小条高，并在胶囊风格下插入灰底容器
    func prepareSetupMetrics(from configuration: ChatInputBarConfiguration) -> ChatInputBarSetupMetrics {
        // 行为与风格参数
        keyboardSendEnabled = configuration.keyboardSendEnabled
        heightChangeDuration = configuration.inputBarHeightChangeAnimationDuration == 0
            ? 0.2
            : configuration.inputBarHeightChangeAnimationDuration
        layoutStyle = configuration.layoutStyle
        voiceButtonPlacement = configuration.voiceButtonPlacement
        capsuleHorizontalInset = configuration.capsuleHorizontalInset
        capsuleVerticalInset = configuration.capsuleVerticalInset
        capsuleCornerRadius = configuration.capsuleCornerRadius

        let isCapsule = layoutStyle == .capsule
        let preferredContentH = contentMinHeight

        // 贴底：按钮底 inset；输入底 = 按钮底 + (40−36)/2，单行对称
        let buttonBottomInset = isCapsule ? capsuleButtonBottomInset : (preferredContentH - switchButtonWidth) / 2
        verticalPadding = buttonBottomInset
        let textBottomInset = buttonBottomInset + (switchButtonWidth - ChatInputBarView.textViewMinHeight) / 2

        // 首帧条高不足时先撑满，避免贴底错位
        if bounds.height < preferredContentH {
            var resized = frame
            resized.size.height = preferredContentH
            frame = resized
        }

        // 左右基准：胶囊控件落在胶囊内侧，普通样式相对安全区
        let safe = safeAreaInsetsOrWindow()
        let leadingBase = safe.left + (isCapsule ? capsuleHorizontalInset + capsuleInnerPadding : 0)
        let trailingBase = safe.right + (isCapsule ? capsuleHorizontalInset + capsuleInnerPadding : 0)

        // 胶囊灰底先入树，控件稍后 embed
        if isCapsule {
            let capsule = UIView()
            capsule.backgroundColor = configuration.capsuleBackgroundColor
            capsule.layer.cornerRadius = capsuleCornerRadius
            capsule.clipsToBounds = true
            insertSubview(capsule, at: 0)
            capsuleView = capsule
        }

        let showLeadingVoice = !configuration.voiceButtonHidden && voiceButtonPlacement == .leading
        let showTrailingVoice = !configuration.voiceButtonHidden && voiceButtonPlacement == .trailing
        let rowBottom = isCapsule
            ? max(contentYOffset + capsuleDefaultHeight, bounds.height - capsuleVerticalInset)
            : contentYOffset + preferredContentH

        return ChatInputBarSetupMetrics(
            isCapsule: isCapsule,
            preferredContentH: preferredContentH,
            buttonBottomInset: buttonBottomInset,
            textBottomInset: textBottomInset,
            leadingBase: leadingBase,
            trailingBase: trailingBase,
            rowBottom: rowBottom,
            buttonsY: rowBottom - buttonBottomInset - switchButtonWidth,
            voiceImage: configuration.voiceSwitchImage ?? ChatKeyboardIcon.voiceSwitch,
            keyboardImage: configuration.keyboardSwitchImage ?? ChatKeyboardIcon.keyboardSwitch,
            emotionImage: configuration.emotionSwitchImage ?? ChatKeyboardIcon.emotionSwitch,
            extendImage: configuration.extendSwitchImage ?? ChatKeyboardIcon.extendSwitch,
            recordNormalImage: configuration.recordBackgroundImage ?? ChatKeyboardIcon.recordBackground,
            recordPressedImage: configuration.recordBackgroundPressedImage ?? ChatKeyboardIcon.recordBackgroundPressed,
            showLeadingVoice: showLeadingVoice,
            showTrailingVoice: showTrailingVoice
        )
    }

    /// 安装左语音与右侧「发送 / + / 表情 / 右语音」，返回输入容器水平区间
    func installSwitchButtons(configuration: ChatInputBarConfiguration, metrics: ChatInputBarSetupMetrics) -> ChatInputBarSetupHorizontalRange {
        var range = ChatInputBarSetupHorizontalRange(minX: 0, rightViewsMinX: 0)
        var rightButtonShowed = false

        // 左侧语音：有则占 leading；无则按风格留白
        if metrics.showLeadingVoice {
            let button = makeSwitchButton(
                normalImage: metrics.voiceImage,
                selectedImage: metrics.keyboardImage,
                action: #selector(onVoiceSwitchButtonClick(_:)),
                flexibleLeft: false
            )
            button.frame.origin = CGPoint(x: horizontalPadding + metrics.leadingBase, y: metrics.buttonsY)
            addSubview(button)
            voiceSwitchButton = button
            range.minX = button.frame.maxX + textViewButtonSpacing
        } else {
            range.minX = metrics.leadingBase + (metrics.isCapsule ? 0 : textContainerEdgeInset)
        }

        // 右侧自右向左：发送 → + → 表情 → 右语音
        if let button = configuration.rightSendButton {
            button.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
            var frame = button.frame
            // Y 待输入容器创建后再底对齐
            frame.origin = CGPoint(x: bounds.width - horizontalPadding - frame.width - metrics.trailingBase, y: 0)
            button.frame = frame
            addSubview(button)
            range.rightViewsMinX = frame.minX
            rightSendButton = button
            rightButtonShowed = true
        }

        // 「+」与发送并存时先藏发送，有字再切回发送
        if !configuration.extendButtonHidden {
            let button = makeSwitchButton(
                normalImage: metrics.extendImage,
                selectedImage: nil,
                action: #selector(onExtendSwitchButtonClick(_:)),
                flexibleLeft: true
            )
            placeTrailingSwitchButton(button, buttonsY: metrics.buttonsY, trailingBase: metrics.trailingBase, rightViewsMinX: &range.rightViewsMinX, rightButtonShowed: rightButtonShowed)
            extendSwitchButton = button
            rightButtonShowed = true
            rightSendButton?.isHidden = true
        }

        if !configuration.emotionButtonHidden {
            let button = makeSwitchButton(
                normalImage: metrics.emotionImage,
                selectedImage: metrics.keyboardImage,
                action: #selector(onEmotionSwitchButtonClick(_:)),
                flexibleLeft: true
            )
            placeTrailingSwitchButton(button, buttonsY: metrics.buttonsY, trailingBase: metrics.trailingBase, rightViewsMinX: &range.rightViewsMinX, rightButtonShowed: rightButtonShowed)
            emotionSwitchButton = button
            rightButtonShowed = true
        }

        if metrics.showTrailingVoice {
            let button = makeSwitchButton(
                normalImage: metrics.voiceImage,
                selectedImage: metrics.keyboardImage,
                action: #selector(onVoiceSwitchButtonClick(_:)),
                flexibleLeft: true
            )
            placeTrailingSwitchButton(button, buttonsY: metrics.buttonsY, trailingBase: metrics.trailingBase, rightViewsMinX: &range.rightViewsMinX, rightButtonShowed: rightButtonShowed)
            voiceSwitchButton = button
        }

        return range
    }

    /// 创建输入圆角容器、TextView，以及中心 / 右下角插槽与录音盖层
    func installInputSurface(
        configuration: ChatInputBarConfiguration,
        metrics: ChatInputBarSetupMetrics,
        horizontal: ChatInputBarSetupHorizontalRange
    ) {
        // 由左右锚点定容器宽与贴底 Y
        let maxX: CGFloat
        if horizontal.rightViewsMinX > 0 {
            maxX = horizontal.rightViewsMinX - textViewButtonSpacing
        } else {
            maxX = bounds.width - metrics.trailingBase - (metrics.isCapsule ? 0 : textContainerEdgeInset)
        }

        let containerWidth = max(0, maxX - horizontal.minX)
        let containerY = metrics.rowBottom - metrics.textBottomInset - ChatInputBarView.textViewMinHeight
        let container = UIView(frame: CGRect(x: horizontal.minX, y: containerY, width: containerWidth, height: ChatInputBarView.textViewMinHeight))
        container.autoresizingMask = .flexibleWidth
        container.layer.cornerRadius = metrics.isCapsule ? 0 : capsuleCornerRadius
        container.clipsToBounds = true
        container.backgroundColor = configuration.textViewBackgroundColor
        addSubview(container)
        textContainerView = container
        alignRightSendButtonToTextContainer()

        // TextView：自定义优先，否则库内 ChatInputTextView
        let textView = makeInputTextView(from: configuration)
        configureTextViewInsets(textView, metrics: metrics)
        textView.delegate = self
        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        let margin = ChatInputBarView.textContainerVerticalMargin
        textView.frame = CGRect(x: 0, y: margin, width: container.bounds.width, height: container.bounds.height - margin * 2)
        container.addSubview(textView)
        inputTextView = textView

        // 可选中心插槽、输入区右侧 inset
        if let center = configuration.centerContentView {
            centerContentView = center
            center.frame = container.frame
            addSubview(center)
        }
        if let insetRight = configuration.inputInsetRightView {
            inputInsetRightView = insetRight
            let w = insetRight.frame.width
            let h = insetRight.frame.height
            insetRight.frame = CGRect(
                x: container.frame.maxX - w - 6,
                y: container.frame.minY + (container.frame.height - h) / 2,
                width: w,
                height: h
            )
            addSubview(insetRight)
        }

        previousTextViewContentHeight = textViewContentHeight()

        // 录音盖：有语音按钮才建，默认透明，与输入互斥淡入
        guard !configuration.voiceButtonHidden else { return }
        let record: UIView
        if let custom = configuration.customRecordView {
            record = custom
        } else {
            let button = UIButton(type: .custom)
            button.frame = container.frame
            button.autoresizingMask = .flexibleWidth
            button.layer.cornerRadius = metrics.isCapsule ? 0 : capsuleCornerRadius
            button.clipsToBounds = true
            button.setBackgroundImage(metrics.recordNormalImage, for: .normal)
            button.setBackgroundImage(metrics.recordPressedImage, for: .highlighted)
            button.setTitle(configuration.speakButtonTitle ?? "按住说话", for: .normal)
            button.setTitleColor(configuration.recordButtonTitleColor, for: .normal)
            record = button
        }
        record.alpha = 0
        addSubview(record)
        recordCenterView = record
    }

    /// 条背景、字色、顶线，以及胶囊坐标收尾
    func finishSetupChrome(configuration: ChatInputBarConfiguration, isCapsule: Bool) {
        backgroundColor = configuration.inputBarBackgroundColor
        inputTextView.textColor = configuration.textColor
        // 圆角底在 textContainerView；库内 TextView 保持透明
        if configuration.customTextView == nil {
            inputTextView.backgroundColor = .clear
        }

        // 顶线 Auto Layout 贴顶；胶囊或无色时隐藏
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = configuration.inputBarBoardColor
        line.isHidden = isCapsule || configuration.inputBarBoardColor == .clear
        addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: topAnchor),
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: ChatKeyboardCommon.hairlineHeight)
        ])
        topLineView = line

        // 胶囊：量高 → embed 转局部坐标 → 再量高 → 钉按钮；普通样式只走 chrome 排布
        layoutCapsuleChrome()
        guard isCapsule else { return }
        embedInputChromeInCapsule()
        layoutCapsuleChrome()
        relayoutBottomAlignedButtons()
    }

    // MARK: - setup 私有零件

    /// 统一创建 40×40 开关按钮
    func makeSwitchButton(normalImage: UIImage?, selectedImage: UIImage?, action: Selector, flexibleLeft: Bool) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: switchButtonWidth, height: switchButtonWidth)
        var mask: UIView.AutoresizingMask = [.flexibleTopMargin]
        if flexibleLeft { mask.insert(.flexibleLeftMargin) }
        button.autoresizingMask = mask
        button.setBackgroundImage(normalImage, for: .normal)
        if let selectedImage {
            button.setBackgroundImage(selectedImage, for: .selected)
        }
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    /// 把开关按钮贴到右侧链上，并更新 `rightViewsMinX`
    func placeTrailingSwitchButton(
        _ button: UIButton,
        buttonsY: CGFloat,
        trailingBase: CGFloat,
        rightViewsMinX: inout CGFloat,
        rightButtonShowed: Bool
    ) {
        var frame = button.frame
        if rightButtonShowed {
            frame.origin = CGPoint(x: rightViewsMinX - frame.width - itemHorizontalSpace, y: buttonsY)
        } else {
            frame.origin = CGPoint(x: bounds.width - horizontalPadding - frame.width - trailingBase, y: buttonsY)
        }
        button.frame = frame
        addSubview(button)
        rightViewsMinX = frame.minX
    }

    /// 创建输入框：自定义 TextView 或库内 ChatInputTextView
    func makeInputTextView(from configuration: ChatInputBarConfiguration) -> UITextView {
        if let custom = configuration.customTextView {
            if custom.font == nil {
                custom.font = ChatInputBarView.textFont
            }
            return custom
        }

        let input = ChatInputTextView(frame: .zero)
        input.font = ChatInputBarView.textFont
        input.returnKeyType = .send
        input.scrollsToTop = false
        input.textAlignment = .left
        input.enablesReturnKeyAutomatically = true
        input.backgroundColor = .clear
        input.placeholder = configuration.placeholder
        input.maxTextLength = configuration.maxTextLength
        return input
    }

    /// 按字高与风格设置 TextView 内边距（胶囊左语音时左边距为 0）
    func configureTextViewInsets(_ textView: UITextView, metrics: ChatInputBarSetupMetrics) {
        let font = textView.font ?? ChatInputBarView.textFont
        let lineHeight = ceil(font.lineHeight)
        let verticalInset = max(0, (ChatInputBarView.textViewFrameMinHeight - lineHeight) / 2)
        let textInset = ChatInputBarView.textContainerInset
        let capsuleTextLeading: CGFloat = metrics.showLeadingVoice ? 0 : textInset.left
        textView.textContainerInset = UIEdgeInsets(
            top: verticalInset,
            left: metrics.isCapsule ? capsuleTextLeading : textInset.left,
            bottom: verticalInset,
            right: textInset.right
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.autoresizingMask = .flexibleWidth
    }
}
