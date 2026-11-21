//
//  SubmitToolBarView.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/19/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 自定义评论输入条：布局自定义；输入区高度逻辑对齐 `ChatInputBarView`
final class SubmitToolBarView: UIView {

    /// 点击工具图标
    var onToolTap: ((ToolKind) -> Void)?
    /// 点击发送
    var onSendTap: (() -> Void)?
    /// 点击快捷表情
    var onQuickEmojiTap: ((String) -> Void)?
    /// 整条高度变化（换行增高时通知 Manager）
    var onBarHeightChange: ((_ delta: CGFloat, _ becauseSendText: Bool) -> Void)?

    enum ToolKind {
        case voice, image, mention, emotion, more
    }

    /// 对外输入框（Manager.bindTextView）
    let textView = ChatInputTextView()

    private let inputCard = UIView()
    private let toolRow = UIStackView()
    private let sendButton = UIButton(type: .system)
    private let emotionButton = UIButton(type: .system)
    private let emojiScrollView = UIScrollView()
    private let emojiStack = UIStackView()

    private let brandPink = UIColor(red: 1, green: 36 / 255, blue: 66 / 255, alpha: 1)
    private let brandPinkDisabled = UIColor(red: 1, green: 36 / 255, blue: 66 / 255, alpha: 0.35)

    /// 顶/底与行间距（仅外层布局）
    private let topPadding: CGFloat = 12
    private let sectionSpacing: CGFloat = 8
    private let toolRowHeight: CGFloat = 36
    private let emojiRowHeight: CGFloat = 44
    private let bottomPadding: CGFloat = 8

    /// 空态默认可见行数（评论框偏高；仍用库的行高推算）
    private static let defaultVisibleLines = 3
    /// TextView 相对灰底卡片的外边距：上下 8、左右 4（会体现在 frame 的 x/y 上）
    private static let textViewMargin = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)

    /// TextView 内容区最小高度（约 N 行）
    static var minTextViewContentHeight: CGFloat {
        let line = ceil(ChatInputBarView.textFont.lineHeight)
        return line * CGFloat(defaultVisibleLines)
    }

    /// 输入卡片最小高度 = TextView 高 + 上下外边距
    static var minInputCardHeight: CGFloat {
        minTextViewContentHeight + textViewMargin.top + textViewMargin.bottom
    }

    /// 默认总高度 = 顶边距 + 卡片 + 间距 + 工具行 + 间距 + 表情行 + 底边距
    static var preferredHeight: CGFloat {
        12 + minInputCardHeight + 8 + 36 + 8 + 44 + 8
    }

    /// 当前应有的总高度（卡片变高时与 frame 同步）
    private func barHeight(forInputCardHeight cardH: CGFloat) -> CGFloat {
        topPadding + cardH + sectionSpacing + toolRowHeight + sectionSpacing + emojiRowHeight + bottomPadding
    }

    /// 与 `ChatInputBarView` 相同：追踪 TextView 内容高（含内部 inset）
    private var previousTextViewContentHeight: CGFloat = 0
    private var clearInputTextBySendSoon = false
    private var inputCardHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        refreshSendEnabled()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        textView.removeObserver(self, forKeyPath: "contentSize")
    }

    var isEmotionSelected: Bool {
        get { emotionButton.isSelected }
        set { emotionButton.isSelected = newValue }
    }

    var plainText: String {
        textView.normalText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 发送后清空（对齐库的 clear 语义）
    func clearTextAfterSend() {
        clearInputTextBySendSoon = true
        textView.text = nil
        textViewDidChange(textView)
        clearInputTextBySendSoon = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTextViewInCard()
    }
}

// MARK: - UI

private extension SubmitToolBarView {

    func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true

        // 输入圆角容器：角色同 ChatInputBarView.textContainerView
        inputCard.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.18, alpha: 1)
                : UIColor(white: 0.96, alpha: 1)
        }
        inputCard.layer.cornerRadius = 12
        inputCard.clipsToBounds = true

        // 字体复用库；文字相对 TextView 内部再垂直居中（单行算法），外边距见 textViewMargin
        textView.font = ChatInputBarView.textFont
        textView.placeholder = "留下你的想法吧"
        textView.placeholderColor = .placeholderText
        textView.backgroundColor = .clear
        textView.textContainerInset = ChatInputBarView.textContainerInset
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        previousTextViewContentHeight = Self.minTextViewContentHeight

        toolRow.axis = .horizontal
        toolRow.alignment = .center
        toolRow.spacing = 18

        let voice = makeToolButton(symbol: "mic", kind: .voice)
        let image = makeToolButton(symbol: "photo", kind: .image)
        let mention = makeToolButton(symbol: "at", kind: .mention)
        configureEmotionButton()
        let more = makeToolButton(symbol: "plus", kind: .more)
        [voice, image, mention, emotionButton, more].forEach { toolRow.addArrangedSubview($0) }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        toolRow.addArrangedSubview(spacer)

        var sendConfig = UIButton.Configuration.filled()
        sendConfig.title = "发送"
        sendConfig.baseForegroundColor = .white
        sendConfig.background.cornerRadius = 14
        sendConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        sendConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        sendButton.configuration = sendConfig
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        toolRow.addArrangedSubview(sendButton)

        emojiScrollView.showsHorizontalScrollIndicator = false
        emojiStack.axis = .horizontal
        emojiStack.spacing = 10
        emojiStack.alignment = .center
        emojiScrollView.addSubview(emojiStack)

        for emoji in ["😊", "😂", "😍", "👍", "🔥", "✨", "🥰", "👏", "😭", "🤔", "🙌", "❤️"] {
            let button = UIButton(type: .system)
            button.setTitle(emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 28)
            button.addAction(UIAction { [weak self] _ in
                self?.onQuickEmojiTap?(emoji)
            }, for: .touchUpInside)
            button.snp.makeConstraints { make in
                make.width.height.equalTo(40)
            }
            emojiStack.addArrangedSubview(button)
        }

        addSubview(inputCard)
        inputCard.addSubview(textView)
        addSubview(toolRow)
        addSubview(emojiScrollView)

        // 只从上往下排，不钉 bottom——整条高度由 frame 管（同 ChatInputBarView），
        // 避免与 Manager 的 AutoresizingMask 高度约束打架
        inputCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topPadding)
            make.leading.trailing.equalToSuperview().inset(12)
            inputCardHeightConstraint = make.height.equalTo(Self.minInputCardHeight).constraint
        }
        toolRow.snp.makeConstraints { make in
            make.top.equalTo(inputCard.snp.bottom).offset(sectionSpacing)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(toolRowHeight)
        }
        emojiScrollView.snp.makeConstraints { make in
            make.top.equalTo(toolRow.snp.bottom).offset(sectionSpacing)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(emojiRowHeight)
        }
        emojiStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
            make.height.equalToSuperview()
        }
    }

    /// TextView 相对卡片：上/下 8、左/右 4（Debugger 里应看到 x=4、y=8）
    func layoutTextViewInCard() {
        let inset = Self.textViewMargin
        textView.frame = CGRect(
            x: inset.left,
            y: inset.top,
            width: max(0, inputCard.bounds.width - inset.left - inset.right),
            height: max(0, inputCard.bounds.height - inset.top - inset.bottom)
        )
    }

    func makeToolButton(symbol: String, kind: ToolKind) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        button.tintColor = .label
        button.addAction(UIAction { [weak self] _ in
            self?.onToolTap?(kind)
        }, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        return button
    }

    func configureEmotionButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        emotionButton.setImage(UIImage(systemName: "face.smiling", withConfiguration: config), for: .normal)
        emotionButton.setImage(UIImage(systemName: "keyboard", withConfiguration: config), for: .selected)
        emotionButton.tintColor = .label
        emotionButton.addAction(UIAction { [weak self] _ in
            self?.onToolTap?(.emotion)
        }, for: .touchUpInside)
        emotionButton.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
    }

    @objc func handleSend() {
        onSendTap?()
    }

    func refreshSendEnabled() {
        let enabled = !plainText.isEmpty
        sendButton.isEnabled = enabled
        var config = sendButton.configuration ?? .filled()
        config.baseBackgroundColor = enabled ? brandPink : brandPinkDisabled
        sendButton.configuration = config
    }

    /// 同库：sizeThatFits 得到内容高；下限为本条默认可见行数
    func textViewContentHeight() -> CGFloat {
        let minH = Self.minTextViewContentHeight
        let maxH = ChatInputBarView.textViewFrameMaxHeight
        let fitted = ceil(textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)).height)
        return min(max(minH, fitted), maxH)
    }
}

// MARK: - 增高（对齐 ChatInputBarView contentSize KVO）

extension SubmitToolBarView {

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard object as AnyObject? === textView, keyPath == "contentSize" else { return }

        let newHeight = textViewContentHeight()
        let shouldShrink = newHeight < previousTextViewContentHeight
        var delta = newHeight - previousTextViewContentHeight
        let maxH = ChatInputBarView.textViewFrameMaxHeight
        // 空文本不继续长高；缩回时仍可落到默认 N 行
        if !shouldShrink && (previousTextViewContentHeight == maxH || (textView.text ?? "").isEmpty) {
            delta = 0
        } else if shouldShrink {
            delta = max(delta, Self.minTextViewContentHeight - previousTextViewContentHeight)
        } else {
            delta = min(delta, maxH - previousTextViewContentHeight)
        }

        if delta != 0 {
            let becauseSend = clearInputTextBySendSoon
            // 卡片高 = TextView 内容高 + 上下外边距 8*2
            let cardH = newHeight + Self.textViewMargin.top + Self.textViewMargin.bottom
            UIView.animate(withDuration: becauseSend ? 0.1 : 0.2) {
                self.inputCardHeightConstraint?.update(offset: cardH)
                self.layoutIfNeeded()
                self.layoutTextViewInCard()

                var frame = self.frame
                frame.size.height = self.barHeight(forInputCardHeight: cardH)
                self.frame = frame
                self.onBarHeightChange?(delta, becauseSend)
            }
            previousTextViewContentHeight = min(newHeight, maxH)
        }
        clearInputTextBySendSoon = false
    }
}

// MARK: - UITextViewDelegate

extension SubmitToolBarView: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        isEmotionSelected = false
        if previousTextViewContentHeight == 0 {
            previousTextViewContentHeight = textViewContentHeight()
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        refreshSendEnabled()
    }
}
