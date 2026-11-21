//
//  PlaceholderTextView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 带 placeholder 的 `UITextView`（`ChatInputBarView` 默认输入框）。
///
/// 职责：
/// - 在 `draw` 中于无正文时绘制占位文案
/// - 监听 `textDidChange`，正文/富文本变化时刷新占位显隐
///
/// 用法：
/// - 配置 `placeholder` / `placeholderColor` / `placeholderMargins`
/// - 占位位置跟随 `textContainerInset` 与 `lineFragmentPadding`
open class PlaceholderTextView: UITextView {

    // MARK: - 占位配置

    /// 占位文案；nil 或空则不绘制
    public var placeholder: String? {
        didSet { setNeedsDisplay() }
    }

    /// 占位颜色（默认系统 placeholder）
    public var placeholderColor: UIColor = .placeholderText {
        didSet { setNeedsDisplay() }
    }

    /// 占位相对 `textContainerInset` 的额外偏移
    public var placeholderMargins: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }

    // MARK: - 正文同步

    /// 赋值后重绘，保证占位随清空/写入及时显隐
    public override var text: String! {
        didSet { setNeedsDisplay() }
    }

    /// 富文本赋值后同样重绘（表情 attachment 路径）
    public override var attributedText: NSAttributedString! {
        didSet { setNeedsDisplay() }
    }

    // MARK: - 初始化

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        // 监听自身文本变化，驱动占位重绘
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeNotification),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        // 监听自身文本变化，驱动占位重绘
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeNotification),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }

    /// 移除文本变化监听，避免野指针
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 绘制

    open override func draw(_ rect: CGRect) {
        super.draw(rect)

        // 有正文时不画占位
        guard (text ?? "").isEmpty, let placeholder, !placeholder.isEmpty else { return }

        // 与真实输入文字起点对齐：textContainerInset + lineFragmentPadding + 额外 margins
        let inset = UIEdgeInsets(
            top: textContainerInset.top + placeholderMargins.top,
            left: textContainerInset.left + textContainer.lineFragmentPadding + placeholderMargins.left,
            bottom: textContainerInset.bottom + placeholderMargins.bottom,
            right: textContainerInset.right + placeholderMargins.right
        )
        let drawRect = rect.inset(by: inset)

        // 字体跟 TextView，颜色用 placeholderColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font ?? .systemFont(ofSize: 17),
            .foregroundColor: placeholderColor
        ]
        (placeholder as NSString).draw(in: drawRect, withAttributes: attrs)
    }

    // MARK: - 通知

    /// 用户输入导致文本变化时触发重绘
    @objc private func textDidChangeNotification() {
        setNeedsDisplay()
    }
}
