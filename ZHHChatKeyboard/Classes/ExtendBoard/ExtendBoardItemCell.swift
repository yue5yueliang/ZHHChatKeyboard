//
//  ExtendBoardItemCell.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 扩展入口 Cell：仅 `iconButton` 可点；标题仅展示；角标不拦截点击
open class ExtendBoardItemCell: UICollectionViewCell {

    // MARK: - 子视图

    /// 白底卡片按钮（唯一热区）
    public let iconButton = ExtendBoardIconButton(frame: .zero)
    /// 入口标题（不参与点击）
    public let titleLabel = UILabel()
    /// 右上角角标
    public let badgeLabel = UILabel()

    /// 点击白底卡片
    public var onIconTap: (() -> Void)?

    // MARK: - 角标尺寸约束

    /// 角标宽（胶囊随文案更新；红点固定 8）
    private var badgeWidthConstraint: NSLayoutConstraint!
    /// 角标高
    private var badgeHeightConstraint: NSLayoutConstraint!

    // MARK: - 初始化

    override public init(frame: CGRect) {
        super.init(frame: frame)

        // 卡片按钮
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        iconButton.addTarget(self, action: #selector(iconButtonTapped), for: .touchUpInside)
        contentView.addSubview(iconButton)

        // 标题：仅展示
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = ChatKeyboardColor.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false
        contentView.addSubview(titleLabel)

        // 角标：不拦截点击
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = ChatKeyboardColor.badge
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        badgeLabel.isUserInteractionEnabled = false
        contentView.addSubview(badgeLabel)

        // 无障碍落在 iconButton 上；关掉系统选中底
        isAccessibilityElement = false
        selectedBackgroundView = nil

        setupConstraints()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 约束

    /// 卡片居中且边长 = min(60, 列宽)；标题贴卡片下；角标贴卡片右上
    private func setupConstraints() {
        // 优先铺满列宽，但硬上限 60 → 等价于 min(60, bounds.width)
        let preferredWidth = iconButton.widthAnchor.constraint(equalTo: contentView.widthAnchor)
        preferredWidth.priority = .defaultHigh

        badgeWidthConstraint = badgeLabel.widthAnchor.constraint(equalToConstant: 8)
        badgeHeightConstraint = badgeLabel.heightAnchor.constraint(equalToConstant: 8)

        NSLayoutConstraint.activate([
            iconButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            preferredWidth,
            iconButton.widthAnchor.constraint(lessThanOrEqualToConstant: 60),
            iconButton.heightAnchor.constraint(equalTo: iconButton.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconButton.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 17),

            badgeLabel.topAnchor.constraint(equalTo: iconButton.topAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: iconButton.trailingAnchor, constant: -6),
            badgeWidthConstraint,
            badgeHeightConstraint
        ])
    }

    // MARK: - 复用与配置

    /// 复用前清掉图标、标题、角标与点击回调
    open override func prepareForReuse() {
        super.prepareForReuse()

        iconButton.setIconImage(nil)
        iconButton.resetPressState()
        titleLabel.text = nil
        badgeLabel.isHidden = true
        badgeLabel.text = nil
        onIconTap = nil
    }

    /// 绑定入口模型并刷新角标
    open func configure(item: ExtendBoardItem) {
        // 图标：保留 alwaysOriginal，其余按模板渲染
        if let icon = item.icon {
            let image = icon.withRenderingMode(icon.renderingMode == .alwaysOriginal ? .alwaysOriginal : .alwaysTemplate)
            iconButton.setIconImage(image)
        } else {
            iconButton.setIconImage(nil)
        }

        titleLabel.text = item.title
        iconButton.accessibilityLabel = item.title
        updateBadge(item.badgeText)
    }

    /// 白底卡片 touchUpInside → 触发 `onIconTap`
    @objc private func iconButtonTapped() {
        onIconTap?()
    }

    // MARK: - 角标

    /// 按 `badgeText` 显隐角标并更新宽高约束
    private func updateBadge(_ text: String?) {
        guard let text else {
            badgeLabel.isHidden = true
            badgeLabel.text = nil
            return
        }

        badgeLabel.isHidden = false
        if text.isEmpty {
            // 空字符串：仅显示小红点
            badgeLabel.text = nil
            badgeWidthConstraint.constant = 8
            badgeHeightConstraint.constant = 8
            badgeLabel.layer.cornerRadius = 4
        } else {
            // 胶囊：按文字宽度撑开，最小等于高度
            badgeLabel.text = text
            let paddingH: CGFloat = 5
            let height: CGFloat = 16
            let textWidth = ceil((text as NSString).size(withAttributes: [.font: badgeLabel.font as Any]).width)
            badgeWidthConstraint.constant = max(height, textWidth + paddingH * 2)
            badgeHeightConstraint.constant = height
            badgeLabel.layer.cornerRadius = height / 2
        }
    }
}
