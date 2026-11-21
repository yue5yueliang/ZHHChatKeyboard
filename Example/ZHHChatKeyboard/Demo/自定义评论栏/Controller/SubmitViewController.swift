//
//  SubmitViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 自定义评论栏 Demo：平时藏起，点「写评论」再弹出；由 KeyboardManager 切换面板
final class SubmitViewController: UIViewController {

    private let viewModel = SubmitViewModel()
    private var keyboardManager: KeyboardManager!
    private let toolBar = SubmitToolBarView()
    private let tipLabel = UILabel()
    private let commentButton = UIButton(type: .system)
    private let emotionBoardView = EmotionBoardView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "自定义评论栏"
        view.backgroundColor = .systemBackground
        emotionBoardView.delegate = self
        emotionBoardView.imageLoader = DemoEmotionGIFLoader.shared
        setupUI()
        setupToolBarActions()
        setupKeyboardManager()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager.viewControllerWillDisappear = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardManager.viewControllerWillDisappear = false
    }
}

// MARK: - UI & 组装

private extension SubmitViewController {

    func setupUI() {
        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .center
        tipLabel.textColor = .secondaryLabel
        tipLabel.font = .systemFont(ofSize: 14)
        tipLabel.text = viewModel.tipText
        view.addSubview(tipLabel)

        var config = UIButton.Configuration.filled()
        config.title = "写评论"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor(red: 1, green: 36 / 255, blue: 66 / 255, alpha: 1)
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 28, bottom: 12, trailing: 28)
        commentButton.configuration = config
        commentButton.addTarget(self, action: #selector(openCommentTapped), for: .touchUpInside)
        view.addSubview(commentButton)

        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(commentButton.snp.top).offset(-20)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
        commentButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        toolBar.frame = CGRect(x: 0, y: 0, width: width, height: SubmitToolBarView.preferredHeight)
    }

    func setupToolBarActions() {
        toolBar.onToolTap = { [weak self] kind in
            guard let self else { return }
            switch kind {
            case .emotion:
                self.toggleEmotion()
            case .voice:
                self.tipLabel.text = "语音（示例占位）"
            case .image:
                self.tipLabel.text = "图片（示例占位）"
            case .mention:
                self.tipLabel.text = "@（示例占位）"
            case .more:
                self.tipLabel.text = "更多（示例占位）"
            }
        }
        toolBar.onSendTap = { [weak self] in
            guard let self else { return }
            let text = self.toolBar.plainText
            guard !text.isEmpty else { return }
            self.tipLabel.text = "发送：\(text)"
            self.toolBar.clearTextAfterSend()
            self.keyboardManager.inputTextViewHeightDidChange(becauseSendText: true)
            self.keyboardManager.hideAllBoardView()
        }
        toolBar.onQuickEmojiTap = { [weak self] emoji in
            guard let self else { return }
            self.toolBar.textView.insertText(emoji)
            if self.toolBar.textView.isFirstResponder == false {
                self.toolBar.textView.becomeFirstResponder()
            }
        }
        toolBar.onBarHeightChange = { [weak self] _, becauseSend in
            self?.keyboardManager.inputTextViewHeightDidChange(becauseSendText: becauseSend)
        }
    }

    func setupKeyboardManager() {
        keyboardManager = KeyboardManager(viewController: self)
        keyboardManager.dataSource = self
        keyboardManager.delegate = self
        // 平时藏在屏幕外；点「写评论」再弹出
        keyboardManager.addBottomChatInputBarView(toolBar, belowViewController: true)
        keyboardManager.bindTextView(toolBar.textView)
    }

    @objc func openCommentTapped() {
        toolBar.isEmotionSelected = false
        toolBar.textView.becomeFirstResponder()
    }

    func toggleEmotion() {
        if toolBar.textView.isFirstResponder {
            toolBar.isEmotionSelected = true
            keyboardManager.switchToEmotionBoard()
        } else if toolBar.isEmotionSelected {
            toolBar.isEmotionSelected = false
            toolBar.textView.becomeFirstResponder()
        } else {
            toolBar.isEmotionSelected = true
            keyboardManager.switchToEmotionBoard()
        }
    }
}

// MARK: - KeyboardManagerDataSource

extension SubmitViewController: KeyboardManagerDataSource {

    func keyboardManagerEmotionBoardView(_ manager: KeyboardManager) -> UIView? { emotionBoardView }
    func keyboardManagerExtendBoardView(_ manager: KeyboardManager) -> UIView? { nil }
    func keyboardManagerEmotionBoardHeight(_ manager: KeyboardManager) -> CGFloat { EmotionBoardView.boardHeight }
    func keyboardManagerExtendBoardHeight(_ manager: KeyboardManager) -> CGFloat { 0 }
    func keyboardManagerEmotionGroups(_ manager: KeyboardManager) -> [EmotionGroup] {
        DemoEmotionCatalog.makeGroups()
    }
}

// MARK: - KeyboardManagerDelegate

extension SubmitViewController: KeyboardManagerDelegate {

    func keyboardManager(_ manager: KeyboardManager, wholeInputViewHeightDidChange height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        tipLabel.text = "自定义评论栏 wholeHeight=\(Int(height))"
    }
}

// MARK: - EmotionBoardViewDelegate

extension SubmitViewController: EmotionBoardViewDelegate {

    func emotionView(_ view: EmotionBoardView, didSelect emotion: Emotion, at index: Int, in group: EmotionGroup) {
        switch group.tapAction {
        case .sendDirectly:
            tipLabel.text = "直发贴纸：\(emotion.displayName)"
        case .insertIntoInput:
            let font = toolBar.textView.font ?? .systemFont(ofSize: 16)
            toolBar.textView.insertEmotionAttributedString(
                keyboardManager.emotionHelper.attributedString(imageKey: emotion.displayName, font: font, useCache: false)
            )
        }
    }

    func emotionViewDidSelectAddButton(_ view: EmotionBoardView, in group: EmotionGroup) {
        DemoEmotionAddPresenter.present(from: self, board: view)
    }

    func emotionViewDidSelectDeleteButton(_ view: EmotionBoardView) {
        if !toolBar.textView.deleteEmotion() { toolBar.textView.deleteBackward() }
    }

    func emotionViewDidSelectSendButton(_ view: EmotionBoardView) {
        let text = toolBar.plainText
        tipLabel.text = text.isEmpty ? "内容为空" : "提交：\(text)"
        if !text.isEmpty {
            toolBar.clearTextAfterSend()
            keyboardManager.inputTextViewHeightDidChange(becauseSendText: true)
        }
        keyboardManager.hideAllBoardView()
        toolBar.isEmotionSelected = false
    }
}
