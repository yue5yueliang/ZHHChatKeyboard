//
//  XHSQuickReplyBarView.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/20/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit

/// 胶囊 Demo 快捷短语横滑条（挂在输入条上方）
final class XHSQuickReplyBarView: UIView {

    struct Item {
        let emoji: String
        let text: String

        var displayText: String { "\(emoji) \(text)" }
        var insertText: String { text }
    }

    var onSelect: ((Item) -> Void)?

    static let preferredHeight: CGFloat = 36

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var items: [Item] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload(_ items: [Item]) {
        self.items = items
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (index, item) in items.enumerated() {
            stack.addArrangedSubview(makeChip(item: item, tag: index))
        }
    }

    private func setupUI() {
        backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            // 与胶囊 capsuleHorizontalInset(18) 左缘对齐
            make.leading.trailing.equalToSuperview().inset(18)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
    }

    private func makeChip(item: Item, tag: Int) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = item.displayText
        config.baseForegroundColor = .label
        config.background.backgroundColor = UIColor.secondarySystemBackground
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.tag = tag
        button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard items.indices.contains(sender.tag) else { return }
        onSelect?(items[sender.tag])
    }
}
