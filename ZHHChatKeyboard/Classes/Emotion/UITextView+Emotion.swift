//
//  UITextView+Emotion.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// `UITextView` 表情读写扩展（Emotion 模块）。
///
/// 职责：在光标处插入附件或纯文本 key、按块删除表情、导出可发送的 `normalText`。
/// 用法：与 `EmotionHelper`、`EmotionAttachment` 配合；输入条与自定义评论栏共用。
public extension UITextView {

    // MARK: - 插入

    /// 在光标处插入表情图片附件
    /// - Parameter attributedString: 表情 AttributedString（通常来自 `EmotionHelper`）
    func insertEmotionAttributedString(_ attributedString: NSAttributedString) {
        guard attributedString.length > 0 else { return }

        let content = NSMutableAttributedString(attributedString: self.attributedText ?? NSAttributedString())
        let location = selectedRange.location

        // 在光标插入附件
        content.insert(attributedString, at: location)

        // 新插入片段沿用输入框字体与前景色，避免样式断层
        let font = self.font ?? .systemFont(ofSize: 17)
        let color = self.textColor ?? .label
        content.addAttributes([.font: font, .foregroundColor: color], range: NSRange(location: location, length: attributedString.length))

        // 写回并前移光标到插入末尾
        attributedText = content
        selectedRange = NSRange(location: location + attributedString.length, length: 0)
    }

    /// 在光标处插入表情纯文本，如 `[微笑]`
    /// - Parameter key: 表情 displayName
    func insertEmotion(key: String) {
        // 与输入框当前样式一致
        let font = self.font ?? .systemFont(ofSize: 17)
        let color = self.textColor ?? .label
        let piece = NSAttributedString(string: key, attributes: [.font: font, .foregroundColor: color])

        let content = NSMutableAttributedString(attributedString: attributedText ?? NSAttributedString())
        let location = selectedRange.location

        // 插入纯文本 key，光标挪到 key 之后
        content.insert(piece, at: location)
        attributedText = content
        selectedRange = NSRange(location: location + key.count, length: 0)
    }

    // MARK: - 删除

    /// 优先删除完整表情 attachment / `[...]` 文本块；失败返回 false 交给外部（如删 @人名）
    /// - Returns: 是否成功删除了表情
    @discardableResult
    func deleteEmotion() -> Bool {
        let location = selectedRange.location
        guard location > 0 else { return false }

        let attr = attributedText ?? NSAttributedString()

        // 路径一：光标前是 EmotionAttachment，整段 effectiveRange 一次删掉
        if location <= attr.length {
            let checkLocation = max(0, location - 1)
            if checkLocation < attr.length,
               let attachment = attr.attribute(.attachment, at: checkLocation, effectiveRange: nil) as? EmotionAttachment {
                let mutable = NSMutableAttributedString(attributedString: attr)
                var effective = NSRange(location: 0, length: 0)
                _ = attr.attribute(.attachment, at: checkLocation, effectiveRange: &effective)

                mutable.deleteCharacters(in: effective)
                attributedText = mutable
                selectedRange = NSRange(location: effective.location, length: 0)
                _ = attachment
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
                return true
            }
        }

        // 找不到配对 `[`，交给调用方处理普通退格
        return false
    }

    // MARK: - 导出

    /// 导出纯文本：将 `EmotionAttachment` 还原为 `displayText`（如 `[微笑]`），便于发送 / 存储
    var normalText: String {
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
