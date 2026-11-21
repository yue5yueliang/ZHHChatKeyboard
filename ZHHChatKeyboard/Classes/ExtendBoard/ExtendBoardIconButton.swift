//
//  ExtendBoardIconButton.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - Cell

/// 白底圆角图标按钮：使用 `UIButton.Configuration`，按下切换浅灰高亮
open class ExtendBoardIconButton: UIButton {

    // MARK: - 外观

    /// 正常态卡片底色
    public var normalBackgroundColor: UIColor = ChatKeyboardColor.inputFill {
        didSet { setNeedsUpdateConfiguration() }
    }
    /// 按下 / 高亮态卡片底色
    public var highlightBackgroundColor: UIColor = ChatKeyboardColor.itemCardHighlight {
        didSet { setNeedsUpdateConfiguration() }
    }

    /// 图标相对卡片的内边距
    private let iconInset: CGFloat = 14
    /// 当前图标（走 Configuration）
    private var iconImage: UIImage?
    /// touchDown 立刻置位，避免轻点时 isHighlighted 闪得看不见
    private var isPressing = false

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)

        // 初始 Configuration：圆角白底 + 内边距
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: iconInset,
            leading: iconInset,
            bottom: iconInset,
            trailing: iconInset
        )
        config.background.cornerRadius = 12
        config.background.backgroundColor = normalBackgroundColor
        config.baseForegroundColor = ChatKeyboardColor.primaryText
        configuration = config

        // 按下 / 抬起立刻刷新底色
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchEnd), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 根据 `isPressing` / `isHighlighted` 刷新 Configuration 背景与图标
    open override func updateConfiguration() {
        guard var config = configuration else { return }

        config.image = iconImage
        config.contentInsets = NSDirectionalEdgeInsets(
            top: iconInset,
            leading: iconInset,
            bottom: iconInset,
            trailing: iconInset
        )
        config.background.cornerRadius = 12

        // 按下或系统高亮时切浅灰底
        config.background.backgroundColor = (isPressing || isHighlighted)
            ? highlightBackgroundColor
            : normalBackgroundColor
        config.baseForegroundColor = ChatKeyboardColor.primaryText
        configuration = config
        imageView?.contentMode = .scaleAspectFit
    }

    /// 设置卡片内图标（走 Configuration）
    public func setIconImage(_ image: UIImage?) {
        iconImage = image
        setNeedsUpdateConfiguration()
    }

    /// 手指按下：立刻显示高亮底
    @objc private func handleTouchDown() {
        isPressing = true
        setNeedsUpdateConfiguration()
    }

    /// 手指抬起 / 取消：恢复正常底
    @objc private func handleTouchEnd() {
        isPressing = false
        setNeedsUpdateConfiguration()
    }

    /// 复用时清掉按下态
    func resetPressState() {
        isPressing = false
        setNeedsUpdateConfiguration()
    }
}