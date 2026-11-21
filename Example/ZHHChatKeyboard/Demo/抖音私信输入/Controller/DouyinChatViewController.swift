//
//  DouyinChatViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/21/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 胶囊 · 语音在右：`capsuleTrailing` + 胶囊内回复
final class DouyinChatViewController: BaseKeyboardDemoViewController {

    private let viewModel = DouyinChatViewModel()
    private let tipLabel = UILabel()

    override var boardHeight: CGFloat { EmotionBoardView.boardHeight }

    override func viewDidLoad() {
        title = "胶囊 · 语音在右"
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "隐藏键盘", style: .plain, target: self, action: #selector(hideKeyboardTapped)),
            UIBarButtonItem(title: "回复", style: .plain, target: self, action: #selector(toggleReplyTapped))
        ]
        setupTip()
    }

    override func makeChatInputBarConfiguration() -> ChatInputBarConfiguration {
        ChatInputBarConfiguration.capsuleTrailing()
    }

    override func handleWholeInputHeightChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        tipLabel.text = "capsuleTrailing wholeHeight=\(Int(height)) reason=\(reason.rawValue)"
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

private extension DouyinChatViewController {

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
        title.text = "用户：你好呀"
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
