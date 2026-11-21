//
//  BaseKeyboardDemoViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import ZHHChatKeyboard

/// Demo 基类：组装默认 InputBar、KeyboardManager，以及表情 / 扩展面板
class BaseKeyboardDemoViewController: UIViewController {

    /// 键盘管理器
    private(set) var keyboardManager: KeyboardManager!
    /// 默认输入条
    private(set) var chatInputBarView: ChatInputBarView!

    /// 是否平时隐藏输入条（朋友圈场景为 true）
    var belowViewControllerMode: Bool { false }
    /// 是否启用右侧发送按钮模式
    var useRightSendButton: Bool { false }
    /// 表情面板高度（网格 + 顶部 Tab）
    var boardHeight: CGFloat { EmotionBoardView.boardHeight }

    /// 默认表情面板（数据由 KeyboardManagerDataSource 注入；GIF 组走异步 Loader）
    private lazy var emotionBoardView: EmotionBoardView = {
        let view = EmotionBoardView()
        view.delegate = self
        view.imageLoader = DemoEmotionGIFLoader.shared
        return view
    }()

    /// 默认扩展面板（items 由 KeyboardManagerDataSource 注入）
    private lazy var extendBoardView: ExtendBoardView = {
        let view = ExtendBoardView()
        view.delegate = self
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupInputBarAndManager()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager?.viewControllerWillDisappear = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardManager?.viewControllerWillDisappear = false
    }

    /// 子类可覆写输入条配置
    func makeChatInputBarConfiguration() -> ChatInputBarConfiguration {
        var config = ChatInputBarConfiguration.default()
        if useRightSendButton {
            let send = ChatInputBarView.makeDefaultRightSendButton()
            send.addTarget(self, action: #selector(handleRightSend), for: .touchUpInside)
            config.rightSendButton = send
        }
        return config
    }

    /// 子类可覆写：表情面板 View（默认 EmotionBoardView）
    func makeEmotionBoardView() -> UIView? { emotionBoardView }

    /// 子类可覆写：扩展面板 View（默认 ExtendBoardView）
    func makeExtendBoardView() -> UIView? { extendBoardView }

    /// 子类可覆写：表情面板高度
    func emotionBoardHeight() -> CGFloat { boardHeight }

    /// 子类可覆写：扩展面板内容高度（不含底部安全区；Manager 会再加安全区）
    func extendBoardHeight() -> CGFloat { ExtendBoardView.contentHeight }

    /// 子类可覆写：表情组列表
    func emotionGroups() -> [EmotionGroup] { DemoEmotionCatalog.makeGroups() }

    /// 子类可覆写：「更多」入口
    func extendBoardItems() -> [ExtendBoardItem] { DemoEmotionCatalog.makeExtendBoardItems() }

    /// 子类处理整条输入区域高度变化
    func handleWholeInputHeightChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {}

    /// 子类处理发送文本
    func handleSend(text: String) {}

    /// 子类处理自定义贴纸 / GIF 直接发送（默认走 `handleSend` 文案）
    func handleSendEmotion(_ emotion: Emotion) {
        handleSend(text: emotion.displayName)
    }

    /// 子类处理「更多」入口点击（默认不收起面板）
    func handleExtendItemSelected(_ item: ExtendBoardItem, at index: Int) {}

    /// 按最新 `makeChatInputBarConfiguration()` 重建输入条（Demo 开关热更新）
    func rebuildChatInputBar() {
        guard keyboardManager != nil else { return }
        let config = makeChatInputBarConfiguration()
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        let height = ChatInputBarView.preferredMinHeight(for: config)
        let bar = ChatInputBarView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        bar.setup(with: config)
        bar.delegate = self
        chatInputBarView = bar
        keyboardManager.replaceChatInputBarView(bar)
        keyboardManager.bindTextView(bar.inputTextView)
    }

    /// 右侧发送按钮点击
    @objc func handleRightSend() {
        let text = chatInputBarView.textViewInputNormalText().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        handleSend(text: text)
        _ = chatInputBarView.clearInputTextBySend()
        keyboardManager.inputTextViewHeightDidChange(becauseSendText: true)
    }
}

// MARK: - 组装

private extension BaseKeyboardDemoViewController {

    /// 创建输入条并绑定 KeyboardManager
    func setupInputBarAndManager() {
        let config = makeChatInputBarConfiguration()
        let height = ChatInputBarView.preferredMinHeight(for: config)
        chatInputBarView = ChatInputBarView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: height))
        chatInputBarView.setup(with: config)
        chatInputBarView.delegate = self

        keyboardManager = KeyboardManager(viewController: self)
        keyboardManager.dataSource = self
        keyboardManager.delegate = self
        keyboardManager.addBottomChatInputBarView(chatInputBarView, belowViewController: belowViewControllerMode)
        keyboardManager.bindTextView(chatInputBarView.inputTextView)
    }
}

// MARK: - KeyboardManagerDataSource

extension BaseKeyboardDemoViewController: KeyboardManagerDataSource {

    /// 表情面板 View
    func keyboardManagerEmotionBoardView(_ manager: KeyboardManager) -> UIView? {
        makeEmotionBoardView()
    }

    /// 扩展面板 View（「更多」）
    func keyboardManagerExtendBoardView(_ manager: KeyboardManager) -> UIView? {
        makeExtendBoardView()
    }

    /// 表情面板高度
    func keyboardManagerEmotionBoardHeight(_ manager: KeyboardManager) -> CGFloat {
        emotionBoardHeight()
    }

    /// 扩展面板高度
    func keyboardManagerExtendBoardHeight(_ manager: KeyboardManager) -> CGFloat {
        extendBoardHeight()
    }

    /// 表情组数据；Manager 创建面板时自动注入并配置本会话 emotionHelper
    func keyboardManagerEmotionGroups(_ manager: KeyboardManager) -> [EmotionGroup] {
        emotionGroups()
    }

    /// 「更多」入口数据；Manager 创建面板时自动注入
    func keyboardManagerExtendBoardItems(_ manager: KeyboardManager) -> [ExtendBoardItem] {
        extendBoardItems()
    }
}

// MARK: - KeyboardManagerDelegate

extension BaseKeyboardDemoViewController: KeyboardManagerDelegate {

    func keyboardManager(_ manager: KeyboardManager, wholeInputViewHeightDidChange height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        handleWholeInputHeightChange(height, reason: reason)
    }
}

// MARK: - ChatInputBarViewDelegate

extension BaseKeyboardDemoViewController: ChatInputBarViewDelegate {

    func chatInputBarView(_ bar: ChatInputBarView, onEmotionButtonClick button: UIButton) {
        if button.isSelected {
            keyboardManager.switchToEmotionBoard()
        } else {
            bar.textViewBecomeFirstResponder()
        }
    }

    func chatInputBarView(_ bar: ChatInputBarView, onExtendButtonClick button: UIButton) {
        if button.isSelected {
            keyboardManager.switchToExtendBoard()
        } else {
            bar.textViewBecomeFirstResponder()
        }
    }

    func chatInputBarView(_ bar: ChatInputBarView, onVoiceSwitchButtonClick button: UIButton) {
        if button.isSelected {
            keyboardManager.hideAllBoardView()
        }
    }

    func chatInputBarView(_ bar: ChatInputBarView, onKeyboardSendClick inputNormalText: String) {
        let text = inputNormalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        handleSend(text: text)
        _ = bar.clearInputTextBySend()
        keyboardManager.inputTextViewHeightDidChange(becauseSendText: true)
    }

    func chatInputBarView(_ bar: ChatInputBarView, inputTextView textView: UITextView, heightDidChange changeValue: CGFloat, becauseSendText: Bool) {
        keyboardManager.inputTextViewHeightDidChange(becauseSendText: becauseSendText)
    }

    func chatInputBarView(_ bar: ChatInputBarView, heightDidChangeBecauseReply changeValue: CGFloat, showReplyView: Bool) {
        keyboardManager.inputTextViewHeightDidChange(becauseSendText: false)
    }

    func chatInputBarView(_ bar: ChatInputBarView, heightDidChangeBecauseAboveBar changeValue: CGFloat, showAboveBar: Bool) {
        keyboardManager.inputTextViewHeightDidChange(becauseSendText: false)
    }
}

// MARK: - EmotionBoardViewDelegate

extension BaseKeyboardDemoViewController: EmotionBoardViewDelegate {

    func emotionView(_ view: EmotionBoardView, didSelect emotion: Emotion, at index: Int, in group: EmotionGroup) {
        switch group.tapAction {
        case .sendDirectly:
            handleSendEmotion(emotion)
        case .insertIntoInput:
            let font = chatInputBarView.inputTextView.font ?? .systemFont(ofSize: 17.5)
            let attr = keyboardManager.emotionHelper.attributedString(imageKey: emotion.displayName, font: font, useCache: false)
            chatInputBarView.insertEmotionAttributedString(attr)
        }
    }

    func emotionViewDidSelectAddButton(_ view: EmotionBoardView, in group: EmotionGroup) {
        DemoEmotionAddPresenter.present(from: self, board: view)
    }

    func emotionViewDidSelectDeleteButton(_ view: EmotionBoardView) {
        if !chatInputBarView.deleteEmotion() {
            chatInputBarView.inputTextView.deleteBackward()
        }
    }

    func emotionViewDidSelectSendButton(_ view: EmotionBoardView) {
        let text = chatInputBarView.textViewInputNormalText().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        handleSend(text: text)
        _ = chatInputBarView.clearInputTextBySend()
        keyboardManager.inputTextViewHeightDidChange(becauseSendText: true)
    }
}

// MARK: - ExtendBoardViewDelegate

extension BaseKeyboardDemoViewController: ExtendBoardViewDelegate {

    func didSelectExtendBoardItem(_ item: ExtendBoardItem, at index: Int) {
        handleExtendItemSelected(item, at: index)
    }
}

// MARK: - Demo 回复条关闭按钮

/// 视觉尺寸固定，用负 inset 扩大 `point(inside:)`，不占布局宽
private final class DemoExpandedHitButton: UIButton {
    /// 负值向外扩热区，例如 -13 → 18 图标约等于 44 可点
    var hitTestInsets: UIEdgeInsets = .zero

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.inset(by: hitTestInsets).contains(point)
    }
}

enum DemoReplyCloseButton {
    /// 图标视觉尺寸（固定 18，不靠拉大 frame 当热区）
    static let iconSize: CGFloat = 18
    /// 热区相对图标每边外扩，使可点区域约 44
    static let hitExpansion: CGFloat = 13
    /// 文案相对 replyView 左边距
    static let labelLeading: CGFloat = 6
    /// 关闭按钮相对 replyView 右边距（与左边距对称）
    static let trailingInset: CGFloat = 6
    /// 文案与关闭图标间距
    static let labelIconSpacing: CGFloat = 6

    /// 文案右边界 = 关闭图标左缘 − 间距
    static func labelMaxX(containerWidth: CGFloat) -> CGFloat {
        containerWidth - trailingInset - iconSize - labelIconSpacing
    }

    /// 右侧关闭：frame=18×18，距右 5；热区通过 point(inside:) 外扩，不挤 label
    static func make(rowHeight: CGFloat, containerWidth: CGFloat, target: Any?, action: Selector) -> UIButton {
        let button = DemoExpandedHitButton(type: .system)
        button.frame = CGRect(
            x: containerWidth - trailingInset - iconSize,
            y: (rowHeight - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        button.hitTestInsets = UIEdgeInsets(
            top: -hitExpansion,
            left: -hitExpansion,
            bottom: -hitExpansion,
            right: -hitExpansion
        )
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular),
            forImageIn: .normal
        )
        button.tintColor = .tertiaryLabel
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}
