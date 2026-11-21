//
//  EmotionGroupTabCell.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 顶部表情组 Tab 格：有 `icon` 显示图，否则显示组标题文字。
final class EmotionGroupTabCell: UICollectionViewCell {

    /// 组图标（有图时优先显示）
    private let imageView = UIImageView()
    /// 无图标时的组标题文字
    private let titleLabel = UILabel()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 选中态背景用圆角裁切
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true

        // 图标 / 标题（二选一展示；约束重叠铺满，靠 isHidden 切换）
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = ChatKeyboardColor.primaryText
        titleLabel.textAlignment = .center
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 配置

    /// 绑定组图标/标题与选中态背景
    func configure(group: EmotionGroup, selected: Bool, selectedBackgroundColor: UIColor) {
        // 有 icon 只显示图；否则显示组标题
        let hasIcon = group.icon != nil
        imageView.image = group.icon
        imageView.isHidden = !hasIcon
        titleLabel.text = hasIcon ? nil : group.title
        titleLabel.isHidden = hasIcon

        // 选中高亮底；无障碍同步选中态
        contentView.backgroundColor = selected ? selectedBackgroundColor : .clear
        accessibilityLabel = group.title
        accessibilityTraits = selected ? [.button, .selected] : .button
    }
}
