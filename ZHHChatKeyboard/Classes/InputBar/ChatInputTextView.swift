//
//  ChatInputTextView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 聊天输入用的轻量 `UITextView`（`ChatInputBarView` 默认输入框）。
///
/// 职责（基础版，对齐 ZHHTextKit：能力挂在子类上，不含 `@` / `#`）：
/// - 用 `UILabel` 显示占位，空文且无中文联想未上屏时可见
/// - 可选 `maxTextLength`：按 `String.count` 计字素，超限整段拒绝并回调
/// - 表情插删 / `normalText` 导出（配合 `EmotionHelper` / `EmotionAttachment`）
///
/// 用法：
/// - 配置 `placeholder` / `placeholderColor` / `placeholderMargins`
/// - 需要限制字数时设 `maxTextLength`，可用 `onReachMaxLength` 做 Toast
/// - 自定义输入框若需表情能力，请继承本类，勿再扩 `UITextView`
open class ChatInputTextView: UITextView {

    // MARK: - 占位

    /// 空文占位标签；不参与编辑命中
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        label.isHidden = true
        return label
    }()

    /// 空文占位文案；nil 或空则不显示
    public var placeholder: String? {
        didSet { refreshPlaceholder() }
    }

    /// 占位颜色（默认系统 placeholder）
    public var placeholderColor: UIColor = .placeholderText {
        didSet { placeholderLabel.textColor = placeholderColor }
    }

    /// 占位相对 `textContainerInset` 的额外偏移
    public var placeholderMargins: UIEdgeInsets = .zero {
        didSet { layoutPlaceholderLabel() }
    }

    // MARK: - 字数

    /// 正文最大字数（`String.count` / 字素）。`nil` 表示不限制
    public var maxTextLength: Int?

    /// 触达 `maxTextLength` 且本次插入被拒绝时回调（便于业务 Toast）
    public var onReachMaxLength: (() -> Void)?

    // MARK: - 正文同步

    /// 赋值后刷新占位显隐
    public override var text: String! {
        didSet { refreshPlaceholder() }
    }

    /// 富文本赋值后同样刷新（表情 attachment 路径）
    public override var attributedText: NSAttributedString! {
        didSet { refreshPlaceholder() }
    }

    /// 字体变化时同步占位字号
    public override var font: UIFont? {
        didSet { refreshPlaceholder() }
    }

    /// inset 变化时重排占位
    public override var textContainerInset: UIEdgeInsets {
        didSet { layoutPlaceholderLabel() }
    }

    // MARK: - 初始化

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutPlaceholderLabel()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else { return }
        placeholderLabel.textColor = placeholderColor
    }

    // MARK: - 输入覆盖（字数）

    open override func insertText(_ text: String) {
        // 中文联想未上屏：不按中间态拦长度
        guard markedTextRange == nil else {
            super.insertText(text)
            refreshPlaceholder()
            return
        }
        guard allowInserting(text, replacing: selectedRange) else { return }
        super.insertText(text)
        refreshPlaceholder()
    }

    open override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general.string ?? ""
        guard markedTextRange == nil else {
            super.paste(sender)
            refreshPlaceholder()
            return
        }
        guard allowInserting(pasteboard, replacing: selectedRange) else { return }
        super.paste(sender)
        refreshPlaceholder()
    }

    open override func deleteBackward() {
        super.deleteBackward()
        refreshPlaceholder()
    }

    /// 供 `UITextViewDelegate.shouldChangeTextIn` 复用：判断替换后是否超限
    ///
    /// - Parameters:
    ///   - range: 将被替换的 UTF-16 区间
    ///   - replacement: 待插入文本
    /// - Returns: 允许插入为 `true`；超限已触发 `onReachMaxLength` 时为 `false`
    public func allowsReplacing(_ range: NSRange, with replacement: String) -> Bool {
        // 删除 / 退格始终放行
        if replacement.isEmpty { return true }
        // 联想中间态不拦
        if markedTextRange != nil { return true }
        return allowInserting(replacement, replacing: range)
    }

    // MARK: - 表情（对齐 TextKit：能力在子类上，不含 @ / #）

    /// 在光标处插入表情图片附件
    /// - Parameter attributedString: 表情 AttributedString（通常来自 `EmotionHelper`）
    public func insertEmotionAttributedString(_ attributedString: NSAttributedString) {
        guard attributedString.length > 0 else { return }

        let content = NSMutableAttributedString(attributedString: self.attributedText ?? NSAttributedString())
        let location = selectedRange.location

        // 在光标插入附件
        content.insert(attributedString, at: location)

        // 新插入片段沿用输入框字体与前景色，避免样式断层
        let font = self.font ?? .systemFont(ofSize: 17)
        let color = self.textColor ?? .label
        content.addAttributes([.font: font, .foregroundColor: color], range: NSRange(location: location, length: attributedString.length))

        // 字数：attachment 在 `text` 中占 1 个字素量级的占位，按插入串长度校验
        let probe = String(repeating: "\u{FFFC}", count: attributedString.length)
        guard allowInserting(probe, replacing: selectedRange) else { return }

        // 写回并前移光标到插入末尾
        attributedText = content
        selectedRange = NSRange(location: location + attributedString.length, length: 0)
        refreshPlaceholder()
    }

    /// 在光标处插入表情纯文本，如 `[微笑]`
    /// - Parameter key: 表情 displayName
    public func insertEmotion(key: String) {
        guard allowInserting(key, replacing: selectedRange) else { return }

        // 与输入框当前样式一致
        let font = self.font ?? .systemFont(ofSize: 17)
        let color = self.textColor ?? .label
        let piece = NSAttributedString(string: key, attributes: [.font: font, .foregroundColor: color])

        let content = NSMutableAttributedString(attributedString: attributedText ?? NSAttributedString())
        let location = selectedRange.location

        // 插入纯文本 key，光标挪到 key 之后
        content.insert(piece, at: location)
        attributedText = content
        selectedRange = NSRange(location: location + (key as NSString).length, length: 0)
        refreshPlaceholder()
    }

    /// 优先删除完整表情 attachment / `[...]` 文本块；失败返回 false 交给外部普通退格
    /// - Returns: 是否成功删除了表情
    @discardableResult
    public func deleteEmotion() -> Bool {
        let location = selectedRange.location
        guard location > 0 else { return false }

        let attr = attributedText ?? NSAttributedString()

        // 路径一：光标前是 EmotionAttachment，整段 effectiveRange 一次删掉
        if location <= attr.length {
            let checkLocation = max(0, location - 1)
            if checkLocation < attr.length,
               let _ = attr.attribute(.attachment, at: checkLocation, effectiveRange: nil) as? EmotionAttachment {
                let mutable = NSMutableAttributedString(attributedString: attr)
                var effective = NSRange(location: 0, length: 0)
                _ = attr.attribute(.attachment, at: checkLocation, effectiveRange: &effective)

                mutable.deleteCharacters(in: effective)
                attributedText = mutable
                selectedRange = NSRange(location: effective.location, length: 0)
                refreshPlaceholder()
                return true
            }
        }

        // 路径二：纯文本 `[...]`——光标前必须以 `]` 结尾，再向前找配对的 `[`
        let head = (text as NSString).substring(to: location)
        guard head.hasSuffix("]") else { return false }

        let ns = head as NSString
        for i in stride(from: ns.length, through: 1, by: -1) {
            let ch = ns.character(at: i - 1)
            // 0x5B == '['
            if ch == UInt16(UnicodeScalar(0x5B).value) {
                let mutable = NSMutableAttributedString(attributedString: attr)
                let range = NSRange(location: i - 1, length: location - (i - 1))
                mutable.deleteCharacters(in: range)
                attributedText = mutable
                selectedRange = NSRange(location: i - 1, length: 0)
                refreshPlaceholder()
                return true
            }
        }

        // 找不到配对 `[`，交给调用方处理普通退格
        return false
    }

    /// 导出纯文本：将 `EmotionAttachment` 还原为 `displayText`（如 `[微笑]`），便于发送 / 存储
    public var normalText: String {
        let attr = attributedText ?? NSAttributedString()
        let mutable = NSMutableString(string: attr.string)

        // 逆序枚举，替换 attachment 占位符为 displayText，避免 range 前移错位
        attr.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attr.length), options: .reverse) { value, range, _ in
            if let attachment = value as? EmotionAttachment, let display = attachment.displayText {
                mutable.replaceCharacters(in: range, with: display)
            }
        }

        return mutable as String
    }
}

// MARK: - 初始化与占位

private extension ChatInputTextView {

    /// 公共初始化：占位层 + 文本变化观察
    func commonInit() {
        addSubview(placeholderLabel)
        placeholderLabel.textColor = placeholderColor
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeNotification),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        refreshPlaceholder()
    }

    /// 用户输入导致文本变化时刷新占位（联想过程中也只刷占位）
    @objc func textDidChangeNotification() {
        refreshPlaceholder()
    }

    /// 若设置了 `maxTextLength`，判断替换后是否超限；超限回调并返回 `false`
    @discardableResult
    func allowInserting(_ insertion: String, replacing range: NSRange) -> Bool {
        guard let limit = maxTextLength else { return true }
        let next = text(afterReplacing: range, with: insertion)
        guard next.count <= max(0, limit) else {
            onReachMaxLength?()
            return false
        }
        return true
    }

    /// 用 UTF-16 选区替换后的正文（再按 `String.count` 计字素）
    func text(afterReplacing range: NSRange, with insertion: String) -> String {
        let current = (text ?? "") as NSString
        var safe = range
        if safe.location > current.length {
            safe = NSRange(location: current.length, length: 0)
        }
        if safe.location + safe.length > current.length {
            safe.length = max(0, current.length - safe.location)
        }
        return current.replacingCharacters(in: safe, with: insertion) as String
    }

    /// 刷新占位文案、颜色与显隐
    func refreshPlaceholder() {
        let hasPlaceholder = !(placeholder?.isEmpty ?? true)
        placeholderLabel.text = placeholder
        placeholderLabel.font = font ?? .systemFont(ofSize: 17)
        placeholderLabel.textColor = placeholderColor
        let isEmpty = (text ?? "").isEmpty
        let isMarking = markedTextRange != nil
        placeholderLabel.isHidden = !(hasPlaceholder && isEmpty && !isMarking)
        if !placeholderLabel.isHidden {
            layoutPlaceholderLabel()
        }
    }

    /// 占位框对齐 `textContainerInset`、`lineFragmentPadding` 与 `placeholderMargins`
    func layoutPlaceholderLabel() {
        guard !placeholderLabel.isHidden else { return }
        let inset = textContainerInset
        let pad = textContainer.lineFragmentPadding
        let margins = placeholderMargins
        let x = inset.left + pad + margins.left
        let y = inset.top + margins.top
        let width = bounds.width - inset.left - inset.right - pad * 2 - margins.left - margins.right
        guard width > 0 else { return }
        let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        placeholderLabel.frame = CGRect(x: x, y: y, width: width, height: ceil(size.height))
    }
}
