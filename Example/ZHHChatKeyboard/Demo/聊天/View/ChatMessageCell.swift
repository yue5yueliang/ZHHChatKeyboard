//
//  ChatMessageCell.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 简单聊天气泡 Cell
final class ChatMessageCell: UITableViewCell {

    /// 复用标识
    static let reuseId = "ChatMessageCell"

    /// 气泡背景
    private let bubble = UIView()
    /// 消息文案（支持表情富文本）
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI

private extension ChatMessageCell {

    /// 搭建气泡与约束
    func setupUI() {
        bubble.layer.cornerRadius = 10
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        bubble.setContentHuggingPriority(.required, for: .horizontal)
        bubble.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentView.addSubview(bubble)
        bubble.addSubview(label)

        bubble.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.75)
            make.leading.equalToSuperview().offset(12)
        }
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
    }
}

// MARK: - 配置

extension ChatMessageCell {

    /// 配置消息内容与气泡方位
    /// - Parameters:
    ///   - message: 聊天消息
    ///   - emotionHelper: 本会话图文互转（与 `KeyboardManager.emotionHelper` 相同）
    func configure(_ message: ChatMessage, emotionHelper: EmotionHelper) {
        let font = UIFont.systemFont(ofSize: 18)
        label.attributedText = emotionHelper.attributedString(from: message.text, font: font)
        bubble.backgroundColor = message.isOutgoing ? UIColor.systemBlue : UIColor.secondarySystemBackground
        label.textColor = message.isOutgoing ? .white : .label

        // 按收发重装左右锚点，避免左右同时生效与 maxWidth 冲突
        bubble.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.75)
            if message.isOutgoing {
                make.trailing.equalToSuperview().offset(-12)
            } else {
                make.leading.equalToSuperview().offset(12)
            }
        }
    }
}
