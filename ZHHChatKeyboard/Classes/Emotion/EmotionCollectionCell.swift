//
//  EmotionCollectionCell.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - Cells

/// 单格表情或「添加」占位；贴纸模式可带底部名称。
final class EmotionCollectionCell: UICollectionViewCell {

    /// 按下高亮底（半透明圆角）
    private let highlightView = UIView()
    /// 表情图 / 添加图标
    private let imageView = UIImageView()
    /// 贴纸底部名称（小表情通常隐藏）
    private let titleLabel = UILabel()
    /// 「添加」格虚线边框
    private let dashBorderLayer = CAShapeLayer()

    /// 图片绘制区域尺寸（不含标题）
    private var emotionSize: CGSize = CGSize(width: 34, height: 34)
    /// 是否显示底部名称
    private var showsTitle = false
    /// 当前是否为「添加」占位格
    private var isAddButton = false

    // MARK: - 约束分组

    /// 小表情：图相对 contentView 内缩 5
    private var plainImageConstraints: [NSLayoutConstraint] = []
    /// 贴纸：图置顶居中 + 固定边长，标题贴图下
    private var titledImageConstraints: [NSLayoutConstraint] = []
    /// 「添加」：图居中，边长 ≤28
    private var addImageConstraints: [NSLayoutConstraint] = []
    /// 贴纸模式下图片边长（随 emotionSize 更新）
    private var titledImageWidthConstraint: NSLayoutConstraint!
    private var titledImageHeightConstraint: NSLayoutConstraint!
    /// 「添加」模式下图标边长
    private var addImageSideConstraint: NSLayoutConstraint!

    /// 图片区 frame（供面板计算删/发遮罩与格子的相交区域）
    var emotionImageFrame: CGRect { imageView.frame }

    // MARK: - 高亮

    /// 按下立刻显示高亮，抬起短动画淡出
    override var isHighlighted: Bool {
        didSet {
            let show = isHighlighted
            if show {
                highlightView.alpha = 1
            } else {
                UIView.animate(withDuration: 0.08) {
                    self.highlightView.alpha = 0
                }
            }
        }
    }

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 允许标题/虚线略超出 contentView 边界
        clipsToBounds = false
        contentView.clipsToBounds = false

        // 按下高亮底：半透明圆角，默认透明
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        highlightView.backgroundColor = UIColor(white: 0, alpha: 0.16)
        highlightView.layer.cornerRadius = 6
        highlightView.alpha = 0
        contentView.addSubview(highlightView)

        // 表情图 / 添加图标
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)

        // 贴纸名称：默认隐藏，configure 时再开
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = ChatKeyboardColor.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.isHidden = true
        contentView.addSubview(titleLabel)

        // 「添加」格虚线边框：默认隐藏，layout 时再画 path
        dashBorderLayer.fillColor = UIColor.clear.cgColor
        dashBorderLayer.strokeColor = ChatKeyboardColor.secondaryText.withAlphaComponent(0.45).cgColor
        dashBorderLayer.lineWidth = 1
        dashBorderLayer.lineDashPattern = [4, 3]
        dashBorderLayer.isHidden = true
        contentView.layer.addSublayer(dashBorderLayer)

        // 无系统选中底，用自定义 highlightView
        isAccessibilityElement = true
        accessibilityTraits = .button
        selectedBackgroundView = nil

        setupConstraints()
        updateActiveConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 约束

    /// 高亮铺满；三种图片布局互斥激活
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            highlightView.topAnchor.constraint(equalTo: contentView.topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            highlightView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // 小表情：整格内缩铺图
        plainImageConstraints = [
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ]

        // 贴纸：图在上、名称在下；偏好 emotionSize，列变窄时被 ≤ contentView 压住
        titledImageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: emotionSize.width)
        titledImageWidthConstraint.priority = .defaultHigh
        titledImageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: emotionSize.height)
        titledImageHeightConstraint.priority = .defaultHigh
        titledImageConstraints = [
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titledImageWidthConstraint,
            titledImageHeightConstraint,
            imageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ]

        // 「添加」：图标居中；边长常量可被 ≤ 内缩框压住
        addImageSideConstraint = imageView.widthAnchor.constraint(equalToConstant: 28)
        addImageSideConstraint.priority = .defaultHigh
        addImageConstraints = [
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addImageSideConstraint,
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -10),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor, constant: -10)
        ]
    }

    /// 按当前模式切换图片约束组
    private func updateActiveConstraints() {
        NSLayoutConstraint.deactivate(plainImageConstraints)
        NSLayoutConstraint.deactivate(titledImageConstraints)
        NSLayoutConstraint.deactivate(addImageConstraints)

        if isAddButton {
            // 「+」边长：min(28, 内缩后短边 * 0.45) 在 layoutSubviews 里按实际 bounds 再校正
            addImageSideConstraint.constant = 28
            NSLayoutConstraint.activate(addImageConstraints)
        } else if showsTitle {
            titledImageWidthConstraint.constant = emotionSize.width
            titledImageHeightConstraint.constant = emotionSize.height
            NSLayoutConstraint.activate(titledImageConstraints)
        } else {
            NSLayoutConstraint.activate(plainImageConstraints)
        }
    }

    // MARK: - 布局

    /// 仅维护「添加」格虚线 path，以及按 bounds 校正「+」边长
    override func layoutSubviews() {
        super.layoutSubviews()

        guard isAddButton else { return }

        // 虚线圆角框：相对 contentView 内缩 5pt
        let inset: CGFloat = 5
        let box = contentView.bounds.insetBy(dx: inset, dy: inset)
        dashBorderLayer.frame = contentView.bounds
        dashBorderLayer.path = UIBezierPath(roundedRect: box, cornerRadius: 8).cgPath

        // 「+」边长不超过 28，且不超过虚线框短边的 45%
        let iconSide = min(28, min(box.width, box.height) * 0.45)
        if abs(addImageSideConstraint.constant - iconSide) > 0.5 {
            addImageSideConstraint.constant = iconSide
        }
    }

    // MARK: - 复用与配置

    /// 复用前清掉高亮、遮罩 alpha、标题与添加态，避免脏状态带到下一格
    override func prepareForReuse() {
        super.prepareForReuse()

        // 交互与高亮复位（含面板遮罩可能改过的 alpha）
        highlightView.alpha = 0
        isHighlighted = false
        alpha = 1
        isUserInteractionEnabled = true

        // 标题 / 添加态清空
        titleLabel.text = nil
        titleLabel.isHidden = true
        showsTitle = false
        isAddButton = false
        dashBorderLayer.isHidden = true

        // 去掉模板 tint，留给下次 configure 决定
        imageView.tintColor = nil
        updateActiveConstraints()
    }

    /// 配置为虚线框「+」添加格
    func configureAsAddButton(emotionSize: CGSize) {
        // 标记为添加格，关掉标题
        isAddButton = true
        showsTitle = false
        titleLabel.isHidden = true
        titleLabel.text = nil
        self.emotionSize = emotionSize
        dashBorderLayer.isHidden = false

        // 系统 plus 图标 + 次要色 tint
        imageView.image = UIImage(systemName: "plus")
        imageView.tintColor = ChatKeyboardColor.secondaryText
        imageView.contentMode = .scaleAspectFit
        accessibilityLabel = "添加表情"

        updateActiveConstraints()
        setNeedsLayout()
    }

    /// 配置普通表情格：图片、可选底部标题与无障碍文案
    func configure(image: UIImage?, title: String?, accessibilityLabel: String, emotionSize: CGSize) {
        // 退出添加态，关掉虚线与 tint
        isAddButton = false
        dashBorderLayer.isHidden = true
        dashBorderLayer.path = nil
        imageView.tintColor = nil

        // 图与尺寸、无障碍
        imageView.image = image
        self.accessibilityLabel = accessibilityLabel
        self.emotionSize = emotionSize

        // 有非空标题才显示底部名称（贴纸）
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        showsTitle = !trimmed.isEmpty
        titleLabel.text = trimmed
        titleLabel.isHidden = !showsTitle

        updateActiveConstraints()
    }
}
