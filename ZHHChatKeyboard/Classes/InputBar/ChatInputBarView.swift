//
//  ChatInputBarView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 聊天输入条（库默认实现）。
///
/// 职责概览：
/// - 普通样式：外置语音 / 表情 / +，独立圆角输入容器
/// - 胶囊风格：语音 / 输入 / 表情 / + 共处一体灰底（语音可左可右）
/// - 多行增高、发送清空缩高、回复条、上方配件（快捷短语等）
/// - 通过 `ChatInputBarConfiguration` 一次 `setup`；大改配置请用 `KeyboardManager.replaceChatInputBarView`
///
/// 布局以 frame 为主（贴底算法与键盘动画对齐）；业务侧用 `delegate` 感知高度变化。
open class ChatInputBarView: UIView {

    // MARK: - 尺寸常量

    /// 输入条最小高度（单行，普通样式）
    public static let minHeight: CGFloat = 50
    /// 输入相关圆角（普通输入容器 / 胶囊灰底共用，避免一边 10 一边 12）
    public static let cornerRadius: CGFloat = 10
    /// 胶囊本体最小高度：40 按钮 + 内侧上下各 2
    public static let capsuleContentMinHeight: CGFloat = 44
    /// 按布局风格取初始最小高度。胶囊 = 本体 44 + 外侧上下 inset（默认各 8 → 60），不手写死总高
    /// - Parameters:
    ///   - style: 普通 / 胶囊
    ///   - capsuleVerticalInset: 胶囊相对输入条上下的外边距
    public static func preferredMinHeight(for style: ChatInputBarLayoutStyle, capsuleVerticalInset: CGFloat = 8) -> CGFloat {
        style == .capsule ? capsuleContentMinHeight + capsuleVerticalInset * 2 : minHeight
    }
    /// 从配置取初始最小高度
    /// - Parameter configuration: 含 `layoutStyle` 与 `capsuleVerticalInset`
    public static func preferredMinHeight(for configuration: ChatInputBarConfiguration) -> CGFloat {
        preferredMinHeight(for: configuration.layoutStyle, capsuleVerticalInset: configuration.capsuleVerticalInset)
    }

    /// 单行时输入圆角容器高度
    public static let textViewMinHeight: CGFloat = 36
    /// 输入圆角容器最大高度（约 7 行 + 上下外边距）
    public static let textViewMaxHeight: CGFloat = 147
    /// 默认输入字体
    public static let textFont: UIFont = .systemFont(ofSize: 17.5)
    /// 单行字高（用于计算 TextView 内部上下 inset）
    public static var textContentMinHeight: CGFloat { ceil(textFont.lineHeight) }

    /// TextView 相对输入容器的上下外边距
    public static let textContainerVerticalMargin: CGFloat = 4
    /// 单行时 TextView 高度（容器高 − 上下外边距）
    public static var textViewFrameMinHeight: CGFloat { textViewMinHeight - textContainerVerticalMargin * 2 }
    /// TextView 最大高度（容器最大高 − 上下外边距）
    public static var textViewFrameMaxHeight: CGFloat { textViewMaxHeight - textContainerVerticalMargin * 2 }
    /// TextView 内部边距：上下由「单行 TextView 高 − 字高」均分；右边略小于左边
    public static var textContainerInset: UIEdgeInsets {
        let vertical = max(0, (textViewFrameMinHeight - textContentMinHeight) / 2)
        return UIEdgeInsets(top: vertical, left: 8, bottom: vertical, right: 4)
    }

    // MARK: - 公开状态

    /// 输入框（默认 `ChatInputTextView`，或配置里的 `customTextView`）
    public internal(set) var inputTextView: UITextView!
    /// 当前录音区视图：`customRecordView` 或默认「按住说话」按钮
    public internal(set) var recordCenterView: UIView?

    /// 事件回调
    public weak var delegate: ChatInputBarViewDelegate?

    // MARK: - 子视图（内部）

    /// 圆角输入容器（背景）；TextView 上下各留外边距，文字垂直居中用 textContainerInset
    var textContainerView: UIView!
    /// 覆盖在输入区上的中心插槽（如「按住说话」之外的自定义占位）
    var centerContentView: UIView?
    /// 输入容器内右侧小视图插槽
    var inputInsetRightView: UIView?

    /// 语音 / 键盘切换
    var voiceSwitchButton: UIButton?
    /// 表情 / 键盘切换
    var emotionSwitchButton: UIButton?
    /// 扩展「+」
    var extendSwitchButton: UIButton?
    /// 右侧发送（有内容时显示，可与 + 互斥）
    var rightSendButton: UIButton?

    /// 胶囊内 / 输入下的回复条
    var replyView: UIView?
    /// 输入条上方的配件（如快捷短语）
    var aboveBarView: UIView?
    /// 一体胶囊底（仅 capsule 风格）
    var capsuleView: UIView?
    /// 顶部分隔线（普通样式；胶囊时隐藏）
    var topLineView: UIView?

    /// 回复条相对输入容器的上下间距（显示中才有值）
    var replyViewMargins: (top: CGFloat, bottom: CGFloat)?
    /// 回复条占用的额外高度（marginTop + replyH + marginBottom）
    var replyOccupiedHeight: CGFloat = 0
    /// 上方配件相对条顶的上下间距
    var aboveBarMargins: (top: CGFloat, bottom: CGFloat)?
    /// 上方配件占用高度
    var aboveOccupiedHeight: CGFloat = 0

    /// 切入语音模式时暂存的输入内容（含表情 attachment），切回输入时恢复
    var inputedAttributedText: NSAttributedString?

    // MARK: - 内部配置与布局参数

    /// 追踪 TextView 总高度（含内部 inset，与 sizeThatFits 一致；不含容器上下外边距）
    var previousTextViewContentHeight: CGFloat = 0
    /// 发送清空流程中：KVO 增高/缩高用更短动画
    var clearInputTextBySendSoon = false
    /// 回车是否走发送回调（否则插入换行）
    var keyboardSendEnabled = true
    /// 输入条默认高度变化动画时长
    var heightChangeDuration: TimeInterval = 0.2
    /// 发送清空后的缩高动画时长（通常短于默认）
    var heightChangeWhenSendDuration: TimeInterval = 0.1
    /// `setup(with:)` 是否已执行（防重复搭建）
    private var didSetup = false
    /// 最近一次搭建 / 外观更新用的配置（供 `updateAppearance` 对照）
    private var lastConfiguration: ChatInputBarConfiguration?

    /// 当前布局风格（普通外置按钮 / 一体胶囊）
    var layoutStyle: ChatInputBarLayoutStyle = .standard
    /// 胶囊风格下语音按钮在左或右（左语音 / 右语音）
    var voiceButtonPlacement: ChatInputBarVoicePlacement = .leading

    /// 普通样式：开关按钮相对内容区底的 inset；胶囊风格：按钮底距胶囊底（通常 2）
    var verticalPadding: CGFloat = 0
    /// 胶囊相对屏幕安全区的左右外边距
    var capsuleHorizontalInset: CGFloat = 12
    /// 胶囊相对输入条顶/底的上下外边距
    var capsuleVerticalInset: CGFloat = 8
    /// 胶囊圆角（默认同 `cornerRadius`）
    var capsuleCornerRadius: CGFloat = ChatInputBarView.cornerRadius

    /// 最左/最右按钮相对安全区的外边距
    let horizontalPadding: CGFloat = 6
    /// 右侧按钮之间的水平间距
    let itemHorizontalSpace: CGFloat = 6
    /// 语音 / 表情 / + 开关按钮边长
    let switchButtonWidth: CGFloat = 40
    /// 输入框与相邻开关按钮的间距
    let textViewButtonSpacing: CGFloat = 8
    /// 某一侧无按钮时，输入框相对屏幕安全区的外边距（8 会显得贴边）
    let textContainerEdgeInset: CGFloat = 12

    /// 胶囊内侧左右留白
    let capsuleInnerPadding: CGFloat = 6
    /// 胶囊内按钮贴底间距（40 + 2×2 = 44）
    let capsuleButtonBottomInset: CGFloat = 2
    /// 胶囊内输入容器贴底间距（36 + 2×4 = 44，上下对称）
    let capsuleTextBottomInset: CGFloat = 4
    /// 胶囊本体高度（不含条外侧 inset）
    var capsuleDefaultHeight: CGFloat { Self.capsuleContentMinHeight }

    /// 单行时 TextView 最小高度
    var textViewContentMinHeight: CGFloat { Self.textViewFrameMinHeight }
    /// TextView 最大高度
    var textViewContentMaxHeight: CGFloat { Self.textViewFrameMaxHeight }
    /// 输入控件相对条顶的偏移（上方配件占高）
    var contentYOffset: CGFloat { aboveOccupiedHeight }
    /// 当前风格下输入条最小高度（不含上方配件 / 回复）= 胶囊 44 + 外侧上下 inset
    var contentMinHeight: CGFloat {
        Self.preferredMinHeight(for: layoutStyle, capsuleVerticalInset: capsuleVerticalInset)
    }

    /// 析构时移除 `contentSize` KVO，避免野指针
    deinit {
        inputTextView?.removeObserver(self, forKeyPath: "contentSize")
        inputTextView?.delegate = nil
    }

    // MARK: - 配置搭建

    /// 根据 `ChatInputBarConfiguration` 一次性搭建子视图与布局参数；重复调用无效。
    ///
    /// 分步实现见 `ChatInputBarView+Setup`：参数 → 开关按钮 → 输入面 → 顶线/胶囊收尾。
    /// - Parameter configuration: 颜色、按钮显隐、胶囊/普通样式、自定义 TextView 等
    public func setup(with configuration: ChatInputBarConfiguration) {
        guard !didSetup else { return }
        didSetup = true
        lastConfiguration = configuration

        // 1. 写入风格参数、补最小高度、可选插入胶囊底
        let metrics = prepareSetupMetrics(from: configuration)

        // 2. 左语音 + 右侧发送/+ /表情/右语音，得到输入区水平区间
        let horizontal = installSwitchButtons(configuration: configuration, metrics: metrics)

        // 3. 圆角输入容器、TextView、插槽与录音盖
        installInputSurface(configuration: configuration, metrics: metrics, horizontal: horizontal)

        // 4. 条背景、顶线；胶囊则 embed 并钉按钮
        finishSetupChrome(configuration: configuration, isCapsule: metrics.isCapsule)
    }

    /// 局部更新外观（颜色、图标、placeholder、录音文案等），不重建子视图树。
    ///
    /// - Note: `layoutStyle` / `voiceButtonPlacement` / 按钮显隐等结构变更请用
    ///   `KeyboardManager.replaceChatInputBarView` 整条替换。
    /// - Parameter configuration: 新外观配置
    public func updateAppearance(from configuration: ChatInputBarConfiguration) {
        guard didSetup else {
            setup(with: configuration)
            return
        }
        lastConfiguration = configuration

        // 条与输入区颜色
        backgroundColor = configuration.inputBarBackgroundColor
        topLineView?.backgroundColor = configuration.inputBarBoardColor
        topLineView?.isHidden = layoutStyle == .capsule || configuration.inputBarBoardColor == .clear
        capsuleView?.backgroundColor = configuration.capsuleBackgroundColor
        capsuleView?.layer.cornerRadius = configuration.capsuleCornerRadius
        inputTextView?.textColor = configuration.textColor
        if configuration.customTextView == nil {
            textContainerView?.backgroundColor = configuration.textViewBackgroundColor
        }

        // 开关按钮图标
        let voiceImage = configuration.voiceSwitchImage ?? ChatKeyboardIcon.voiceSwitch
        let keyboardImage = configuration.keyboardSwitchImage ?? ChatKeyboardIcon.keyboardSwitch
        let emotionImage = configuration.emotionSwitchImage ?? ChatKeyboardIcon.emotionSwitch
        let extendImage = configuration.extendSwitchImage ?? ChatKeyboardIcon.extendSwitch
        voiceSwitchButton?.setBackgroundImage(voiceImage, for: .normal)
        voiceSwitchButton?.setBackgroundImage(keyboardImage, for: .selected)
        emotionSwitchButton?.setBackgroundImage(emotionImage, for: .normal)
        emotionSwitchButton?.setBackgroundImage(keyboardImage, for: .selected)
        extendSwitchButton?.setBackgroundImage(extendImage, for: .normal)

        // 默认录音按钮文案 / 底图 / 字色（胶囊未自定义底图时与胶囊同色，不铺白底）
        if let record = recordCenterView as? UIButton, configuration.customRecordView == nil {
            let useCapsuleBlend = layoutStyle == .capsule && configuration.recordBackgroundImage == nil
            let recordNormal = useCapsuleBlend ? nil : (configuration.recordBackgroundImage ?? ChatKeyboardIcon.recordBackground)
            let recordPressed = useCapsuleBlend ? nil : (configuration.recordBackgroundPressedImage ?? ChatKeyboardIcon.recordBackgroundPressed)
            record.backgroundColor = .clear
            record.setBackgroundImage(recordNormal, for: .normal)
            record.setBackgroundImage(recordPressed, for: .highlighted)
            record.setTitle(configuration.speakButtonTitle ?? "按住说话", for: .normal)
            record.setTitleColor(configuration.recordButtonTitleColor, for: .normal)
            record.layer.cornerRadius = configuration.capsuleCornerRadius
            record.layer.cornerCurve = .continuous
            record.clipsToBounds = true
        }

        // placeholder / 字数（仅默认 ChatInputTextView）
        if let input = inputTextView as? ChatInputTextView {
            if let placeholder = configuration.placeholder {
                input.placeholder = placeholder
            }
            input.maxTextLength = configuration.maxTextLength
        }

        keyboardSendEnabled = configuration.keyboardSendEnabled
        if configuration.inputBarHeightChangeAnimationDuration > 0 {
            heightChangeDuration = configuration.inputBarHeightChangeAnimationDuration
        }
    }

    // MARK: - 公开 API（发送按钮 / 输入 / 回复 / 上方配件）

    /// 默认绿色「发送」按钮，可直接赋给 `ChatInputBarConfiguration.rightSendButton`
    /// - Parameters:
    ///   - title: 文案，默认「发送」
    ///   - size: 尺寸；高度建议与 `textViewMinHeight`（36）一致，便于底对齐
    public static func makeDefaultRightSendButton(title: String = "发送", size: CGSize = CGSize(width: 52, height: textViewMinHeight)) -> UIButton {
        // 初始 Configuration：绿底白字
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = ChatKeyboardColor.sendButton
        config.baseForegroundColor = .white
        config.cornerStyle = .fixed
        config.background.cornerRadius = 6

        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.frame = CGRect(origin: .zero, size: size)
        button.accessibilityLabel = title

        // 高亮态在 configurationUpdateHandler 里分步改底色 / 标题色
        button.configurationUpdateHandler = { button in
            guard var updated = button.configuration else { return }
            let pressed = button.isHighlighted || button.isSelected
            // 背景：按下用高亮绿，常态标准绿
            updated.baseBackgroundColor = pressed ? ChatKeyboardColor.sendButtonHighlight : ChatKeyboardColor.sendButton
            // 标题：按下略透明白，常态不透明白
            updated.baseForegroundColor = pressed ? UIColor.white.withAlphaComponent(0.85) : .white
            button.configuration = updated
        }
        return button
    }

    // 焦点
    /// 让输入框成为第一响应者（弹出系统键盘）
    public func textViewBecomeFirstResponder() { inputTextView.becomeFirstResponder() }
    /// 收起输入框焦点
    public func textViewResignFirstResponder() { inputTextView.resignFirstResponder() }

    // 文本与表情（默认 / 自定义输入框需为 `ChatInputTextView` 及其子类）
    /// 导出纯文本（表情 attachment 还原为 `[微笑]`）；非 `ChatInputTextView` 时回退 `text`
    public func textViewInputNormalText() -> String {
        (inputTextView as? ChatInputTextView)?.normalText ?? (inputTextView.text ?? "")
    }
    /// 在光标处插入表情富文本
    public func insertEmotionAttributedString(_ attributedString: NSAttributedString) {
        (inputTextView as? ChatInputTextView)?.insertEmotionAttributedString(attributedString)
    }
    /// 在光标处插入表情纯文本 key，如 `[微笑]`
    public func insertEmotion(key: String) {
        (inputTextView as? ChatInputTextView)?.insertEmotion(key: key)
    }
    /// 删除光标前一个表情片段（attachment 或 `[微笑]` 形式）；成功返回 true
    @discardableResult
    public func deleteEmotion() -> Bool {
        (inputTextView as? ChatInputTextView)?.deleteEmotion() ?? false
    }

    // 发送清空
    /// 发送后清空文本；返回动画时长（单行返回 0）
    @discardableResult
    public func clearInputTextBySend() -> TimeInterval {
        // 单行时 KVO 不会缩高，动画时长返回 0
        let oneLine = abs(inputTextView.frame.height - textViewContentMinHeight) < 0.5

        // 置位后清文本，让 observeValue 走短动画
        clearInputTextBySendSoon = true
        inputTextView.text = nil
        textViewDidChange(inputTextView)
        clearInputTextBySendSoon = false

        return oneLine ? 0 : heightChangeWhenSendDuration
    }

    /// 在输入圆角容器**下方**显示回复条；宽度与 `textContainerView` 对齐。
    /// - Parameters:
    ///   - replyView: 业务自定义回复 View（请先设好自身高度）
    ///   - marginTop: 输入容器底边到回复条顶边的间距
    ///   - marginBottom: 回复条底边到输入条底边的间距
    ///   - animated: 是否动画；条只改 height，贴底由 `ChatKeyboardView` 负责（勿改 origin.y）
    public func showReplyView(_ replyView: UIView, marginTop: CGFloat, marginBottom: CGFloat, animated: Bool = true) {
        // 步骤 1：记录旧占位，移除旧回复视图
        let beforeTotal = replyOccupiedHeight
        if let old = self.replyView {
            old.removeFromSuperview()
        }

        // 步骤 2：算新占位（margin + 视图高 + margin），挂到条或胶囊内
        let replyH = max(replyView.bounds.height, replyView.frame.height)
        let total = marginTop + replyH + marginBottom
        replyViewMargins = (marginTop, marginBottom)
        replyOccupiedHeight = total
        self.replyView = replyView
        replyView.alpha = animated ? 0 : 1

        if let capsuleView {
            capsuleView.addSubview(replyView)
        } else {
            addSubview(replyView)
        }
        layoutReplyViewFrame()
        syncAccessoryViewsWithTextContainer()

        // 步骤 3：条高只加占位差（勿用 alpha 反推高度，淡入前 alpha=0 会被裁切）
        let heightDiff = total - beforeTotal
        let apply = { [weak self] in
            guard let self else { return }

            // 条高 += 回复占位差
            if abs(heightDiff) > 0.5 {
                var frame = self.frame
                frame.size.height += heightDiff
                self.frame = frame
            }

            // 录音/ inset / 回复 frame 跟输入容器；胶囊增高并钉按钮
            self.syncAccessoryViewsWithTextContainer()
            self.layoutCapsuleChrome()
            self.layoutReplyViewFrame()
            self.pinSwitchButtonsToInputRowBottom()
            replyView.alpha = 1
            if abs(heightDiff) > 0.5 {
                self.delegate?.chatInputBarView(self, heightDidChangeBecauseReply: heightDiff, showReplyView: true)
            }
        }
        if animated {
            UIView.animate(withDuration: heightChangeDuration, animations: apply)
        } else {
            apply()
        }
    }

    /// 隐藏输入容器下方的回复条
    /// - Parameter animated: 是否淡出动画
    public func hideReplyView(animated: Bool = true) {
        guard let visibleReply = replyView else { return }

        // 步骤 1：清空占位状态，条高将收回 `removed`
        let removed = replyOccupiedHeight
        replyViewMargins = nil
        replyOccupiedHeight = 0
        replyView = nil

        let heightDiff = -removed
        let apply = { [weak self] in
            guard let self else { return }

            visibleReply.alpha = 0
            // 收回回复占位高度
            if abs(heightDiff) > 0.5 {
                var frame = self.frame
                frame.size.height += heightDiff
                self.frame = frame
            }

            self.syncAccessoryViewsWithTextContainer()
            self.layoutCapsuleChrome()
            self.pinSwitchButtonsToInputRowBottom()
            if abs(heightDiff) > 0.5 {
                self.delegate?.chatInputBarView(self, heightDidChangeBecauseReply: heightDiff, showReplyView: false)
            }
        }
        if animated {
            UIView.animate(withDuration: heightChangeDuration, animations: apply, completion: { _ in
                visibleReply.removeFromSuperview()
            })
        } else {
            apply()
            visibleReply.removeFromSuperview()
        }
    }

    /// 在输入条**上方**显示配件（如快捷短语）；不在胶囊内。
    /// 胶囊模式条高 = aboveOccupied + 胶囊高 + 底 inset（上方块替换原顶 inset，中间不再叠一层）。
    /// - Parameters:
    ///   - view: 上方配件（请先设好高度）
    ///   - marginTop / marginBottom: 条顶→配件、配件→胶囊（建议与 `capsuleVerticalInset` 同为 8）
    ///   - animated: 进页首屏请传 `false`
    public func showAboveBarView(_ view: UIView, marginTop: CGFloat, marginBottom: CGFloat, animated: Bool = true) {
        // 步骤 1：替换旧上方配件，记新占位
        let beforeTotal = aboveOccupiedHeight
        if let old = aboveBarView {
            old.removeFromSuperview()
        }

        let viewH = max(view.bounds.height, view.frame.height)
        let total = marginTop + viewH + marginBottom
        aboveBarMargins = (marginTop, marginBottom)
        aboveOccupiedHeight = total
        aboveBarView = view
        view.alpha = animated ? 0 : 1
        addSubview(view)
        layoutAboveBarFrame()

        // 步骤 2：胶囊按「上条 + 胶囊 + 底 outer」重算目标总高；普通样式则下移输入区
        let heightDiff: CGFloat
        if layoutStyle == .capsule {
            layoutCapsuleChrome()
            let capsuleH = capsuleView?.frame.height ?? capsuleDefaultHeight
            let target = total + capsuleH + capsuleVerticalInset
            heightDiff = target - bounds.height
        } else {
            heightDiff = total - beforeTotal
            offsetInputContentY(by: heightDiff)
        }
        layoutCapsuleChrome()
        relayoutBottomAlignedButtons()

        let apply = { [weak self] in
            guard let self else { return }
            if abs(heightDiff) > 0.5 {
                // 胶囊：总高 = 上条 + 胶囊 + 底 inset；普通样式：已在 offset 下移输入区
                var frame = self.frame
                frame.size.height += heightDiff
                self.frame = frame
                self.layoutAboveBarFrame()
                self.layoutCapsuleChrome()
                self.relayoutBottomAlignedButtons()
                self.delegate?.chatInputBarView(self, heightDidChangeBecauseAboveBar: heightDiff, showAboveBar: true)
            }
            view.alpha = 1
        }
        if animated {
            UIView.animate(withDuration: heightChangeDuration, animations: apply)
        } else {
            apply()
        }
    }

    /// 隐藏上方配件
    /// - Parameter animated: 是否淡出动画
    public func hideAboveBarView(animated: Bool = true) {
        guard let visible = aboveBarView else { return }

        // 步骤 1：清空上方占位状态
        let total = aboveOccupiedHeight
        aboveBarMargins = nil
        aboveOccupiedHeight = 0
        aboveBarView = nil

        // 步骤 2：胶囊恢复「仅上下 outer + 胶囊」；普通样式把输入区上移收回占位
        let heightDiff: CGFloat
        if layoutStyle == .capsule {
            layoutCapsuleChrome()
            let capsuleH = capsuleView?.frame.height ?? capsuleDefaultHeight
            let target = capsuleVerticalInset + capsuleH + capsuleVerticalInset
            heightDiff = target - bounds.height
        } else {
            heightDiff = -total
            offsetInputContentY(by: -total)
        }

        // 步骤 3：淡出、缩高、钉按钮，完成后移除视图
        let apply = { [weak self] in
            guard let self else { return }
            visible.alpha = 0
            if abs(heightDiff) > 0.5 {
                // 缩回「仅胶囊 + 上下 outer」或普通样式输入区已上移后的条高
                var frame = self.frame
                frame.size.height += heightDiff
                self.frame = frame
                self.layoutCapsuleChrome()
                self.relayoutBottomAlignedButtons()
                self.delegate?.chatInputBarView(self, heightDidChangeBecauseAboveBar: heightDiff, showAboveBar: false)
            }
        }
        if animated {
            UIView.animate(withDuration: heightChangeDuration, animations: apply, completion: { _ in
                visible.removeFromSuperview()
            })
        } else {
            apply()
            visible.removeFromSuperview()
        }
    }
}