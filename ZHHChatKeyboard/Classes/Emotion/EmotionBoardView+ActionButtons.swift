//
//  EmotionBoardView+ActionButtons.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 删 / 发按钮

extension EmotionBoardView {

// MARK: - 删 / 发按钮

/// 删除按钮点击：转发给 `delegate`
@objc func handleDelete() {
    delegate?.emotionViewDidSelectDeleteButton(self)
}

/// 发送按钮点击：转发给 `delegate`
@objc func handleSend() {
    delegate?.emotionViewDidSelectSendButton(self)
}

/// 默认删除图标：系统 `delete.backward`
static func makeDefaultDeleteButtonImage() -> UIImage? {
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
    return UIImage(systemName: "delete.backward", withConfiguration: config)
}

/// 将 `deleteButton*` 系列公开属性同步到删除按钮 UI（`UIButton.Configuration`）
func applyDeleteButtonStyle() {
    let normalColor = deleteButtonBackgroundColor ?? ChatKeyboardColor.inputFill
    let highlightColor = deleteButtonHighlightBackgroundColor
    let tint = deleteButtonTintColor
    let radius = deleteButtonCornerRadius
    let icon = deleteButtonImage?.withRenderingMode(.alwaysTemplate)

    // 初始 Configuration：实心底 + 模板图标
    var config = UIButton.Configuration.filled()
    config.baseBackgroundColor = normalColor
    config.baseForegroundColor = tint
    config.image = icon
    config.cornerStyle = .fixed
    config.background.cornerRadius = radius
    config.contentInsets = .zero

    deleteButton.configuration = config
    deleteButton.accessibilityLabel = "删除"

    // 按下切换底色；图标色保持 tint，不再用已弃用的 adjustsImageWhenHighlighted
    deleteButton.configurationUpdateHandler = { button in
        guard var updated = button.configuration else { return }
        let pressed = button.isHighlighted || button.isSelected

        // 底色随按下态切换
        updated.baseBackgroundColor = pressed ? highlightColor : normalColor

        // 图标始终模板 + tint，避免系统再叠一层高亮变暗
        updated.baseForegroundColor = tint
        updated.image = icon

        // 圆角跟公开属性走，避免被系统默认覆盖
        updated.background.cornerRadius = radius
        button.configuration = updated
    }
}

/// 将 `sendButton*` 系列公开属性同步到发送按钮 UI（`UIButton.Configuration`）
func applySendButtonStyle() {
    let normalColor = sendButtonBackgroundColor
    let highlightColor = sendButtonHighlightBackgroundColor
    let radius = sendButtonCornerRadius
    let title = sendButtonTitle
    let titleAttributes = sendButtonTitleAttributes

    // 初始 Configuration：实心底 + 标题
    var config = UIButton.Configuration.filled()
    config.baseBackgroundColor = normalColor
    config.cornerStyle = .fixed
    config.background.cornerRadius = radius
    config.contentInsets = .zero

    // 有自定义 attributes 用 attributedTitle；否则白字 + 固定字号
    if let titleAttributes {
        config.attributedTitle = AttributedString(NSAttributedString(string: title, attributes: titleAttributes))
    } else {
        config.title = title
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17)
            return outgoing
        }
    }

    sendButton.configuration = config
    sendButton.accessibilityLabel = title

    // 按下切换底色；无自定义 attributes 时标题略透明
    sendButton.configurationUpdateHandler = { button in
        guard var updated = button.configuration else { return }
        let pressed = button.isHighlighted || button.isSelected

        // 底色随按下态切换
        updated.baseBackgroundColor = pressed ? highlightColor : normalColor

        // 默认标题色：按下略透明；自定义 attributedTitle 则不动
        if titleAttributes == nil {
            updated.baseForegroundColor = pressed ? UIColor.white.withAlphaComponent(0.85) : .white
        }

        // 圆角跟公开属性走，避免被系统默认覆盖
        updated.background.cornerRadius = radius
        button.configuration = updated
    }
}

    /// 删/发钉在所在 page 右下角（Auto Layout 贴底；切板高度动画时贴屏底不跟着「从中间往下挪」）
    func layoutActionButtonsIfNeeded() {
        // 没有「写入输入框」组时整组隐藏
        guard
            let pageIndex = actionButtonsPageIndex,
            groupPageViews.indices.contains(pageIndex)
        else {
            actionButtonsView.isHidden = true
            return
        }

        let page = groupPageViews[pageIndex]
        // page 尚未完成布局时不要排按钮，否则遮罩会把整页表情算成透明
        guard page.bounds.width > 1, page.bounds.height > 1 else {
            actionButtonsView.isHidden = true
            return
        }

        let buttonSpacing: CGFloat = 10
        let bottomInset = resolvedBottomSafeInset
        let containerW = Self.buttonWidth * 2 + buttonSpacing + sendButtonMargins.right
        let containerH = Self.buttonHeight + sendButtonMargins.bottom + bottomInset

        // 换页或尚未安装：用约束钉在 page 右下，高度变化时由 bottom 锚点稳住屏位
        if actionButtonsInstalledPage !== page || actionButtonsView.superview !== page {
            actionButtonsView.removeFromSuperview()
            actionButtonsView.translatesAutoresizingMaskIntoConstraints = false
            page.addSubview(actionButtonsView)
            let width = actionButtonsView.widthAnchor.constraint(equalToConstant: containerW)
            let height = actionButtonsView.heightAnchor.constraint(equalToConstant: containerH)
            width.priority = UILayoutPriority(999)
            height.priority = UILayoutPriority(999)
            NSLayoutConstraint.activate([
                width,
                height,
                actionButtonsView.trailingAnchor.constraint(equalTo: page.trailingAnchor),
                actionButtonsView.bottomAnchor.constraint(equalTo: page.bottomAnchor)
            ])
            actionButtonsWidthConstraint = width
            actionButtonsHeightConstraint = height
            actionButtonsInstalledPage = page
        } else {
            actionButtonsWidthConstraint?.constant = containerW
            actionButtonsHeightConstraint?.constant = containerH
        }
        actionButtonsView.isHidden = false

        // 钮内：发送靠右，删除在其左（只装一次）
        if sendButton.translatesAutoresizingMaskIntoConstraints {
            sendButton.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sendButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
                sendButton.heightAnchor.constraint(equalToConstant: Self.buttonHeight),
                sendButton.topAnchor.constraint(equalTo: actionButtonsView.topAnchor),
                sendButton.trailingAnchor.constraint(equalTo: actionButtonsView.trailingAnchor, constant: -sendButtonMargins.right),

                deleteButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
                deleteButton.heightAnchor.constraint(equalToConstant: Self.buttonHeight),
                deleteButton.topAnchor.constraint(equalTo: actionButtonsView.topAnchor, constant: deleteButtonOffset.y),
                deleteButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -(buttonSpacing + deleteButtonOffset.x))
            ])
        }

        // 立刻解出 frame，供首进板同步压遮罩（不能等下一轮 layout）
        page.layoutIfNeeded()
        actionButtonsView.layoutIfNeeded()
        updateActionButtonsVeil()
        page.bringSubviewToFront(actionButtonsView)
    }
}
