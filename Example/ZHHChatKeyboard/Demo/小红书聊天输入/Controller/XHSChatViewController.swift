//
//  XHSChatViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/20/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 胶囊 · 语音在左：`capsuleLeading` + 上方快捷短语 + 胶囊内回复
final class XHSChatViewController: BaseKeyboardDemoViewController {

    private let viewModel = XHSChatViewModel()
    private let tipLabel = UILabel()
    private let quickReplyBar = XHSQuickReplyBarView()

    override var boardHeight: CGFloat { EmotionBoardView.boardHeight }

    override func viewDidLoad() {
        title = "胶囊 · 语音在左"
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 248 / 255, green: 248 / 255, blue: 246 / 255, alpha: 1)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "隐藏键盘", style: .plain, target: self, action: #selector(hideKeyboardTapped)),
            UIBarButtonItem(title: "回复", style: .plain, target: self, action: #selector(toggleReplyTapped))
        ]
        setupTip()
        setupQuickReplyIfNeeded()
    }

    override func makeChatInputBarConfiguration() -> ChatInputBarConfiguration {
        ChatInputBarConfiguration.capsuleLeading()
    }

    override func handleWholeInputHeightChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        tipLabel.text = "capsuleLeading wholeHeight=\(Int(height)) reason=\(reason.rawValue)"
    }

    override func handleSend(text: String) {
        tipLabel.text = "发送：\(text)"
        if viewModel.showReply {
            viewModel.showReply = false
            chatInputBarView.hideReplyView()
        }
    }

    override func handleExtendItemSelected(_ item: ExtendBoardItem, at index: Int) {
        tipLabel.text = "扩展：\(item.title)"
    }
}

// MARK: - UI

private extension XHSChatViewController {

    func setupTip() {
        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .center
        tipLabel.textColor = .secondaryLabel
        tipLabel.font = .systemFont(ofSize: 14)
        tipLabel.text = viewModel.tipText
        view.insertSubview(tipLabel, at: 0)
        tipLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    func setupQuickReplyIfNeeded() {
        guard viewModel.showQuickReply else { return }
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        quickReplyBar.frame = CGRect(x: 0, y: 0, width: width, height: XHSQuickReplyBarView.preferredHeight)
        quickReplyBar.reload(viewModel.quickReplyItems)
        quickReplyBar.onSelect = { [weak self] item in
            guard let self else { return }
            self.chatInputBarView.inputTextView.insertText(item.insertText)
            self.chatInputBarView.textViewBecomeFirstResponder()
        }
        // 进页首屏不要动画；三段间距与 capsuleVerticalInset 同为 8
        chatInputBarView.showAboveBarView(quickReplyBar, marginTop: 8, marginBottom: 8, animated: false)
    }

    @objc func hideKeyboardTapped() {
        keyboardManager.hideAllBoardView()
    }

    @objc func toggleReplyTapped() {
        viewModel.showReply.toggle()
        if viewModel.showReply {
            chatInputBarView.showReplyView(makeReplyView(), marginTop: 4, marginBottom: 8)
        } else {
            chatInputBarView.hideReplyView()
        }
    }

    func makeReplyView() -> UIView {
        let height: CGFloat = 28
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: height))
        container.backgroundColor = .clear

        let close = DemoReplyCloseButton.make(
            rowHeight: height,
            containerWidth: container.bounds.width,
            target: self,
            action: #selector(replyCloseTapped)
        )
        container.addSubview(close)

        let leading = DemoReplyCloseButton.labelLeading
        let titleW = DemoReplyCloseButton.labelMaxX(containerWidth: container.bounds.width) - leading
        let title = UILabel(frame: CGRect(x: leading, y: 0, width: max(0, titleW), height: height))
        title.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        title.text = "桃色了呐个夏：行"
        title.textColor = .secondaryLabel
        title.font = .systemFont(ofSize: 13)
        container.addSubview(title)
        return container
    }

    @objc func replyCloseTapped() {
        viewModel.showReply = false
        chatInputBarView.hideReplyView()
    }
}
