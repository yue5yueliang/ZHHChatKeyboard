//
//  EmotionHelper.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 表情图文互转工具：`[微笑]` ↔ `EmotionAttachment`（Emotion 模块）。
///
/// 职责：维护 displayName → Image 映射，提供单 key / 整段纯文本转富文本。
/// 用法：
/// - 按会话创建实例；推荐使用 `KeyboardManager.emotionHelper`，与表情面板共用。
/// - 映射表必须由业务注入（`configure(groups:)` / `configure(emotions:)`）；库不内置可商用表情。
/// - `KeyboardManager` 在 DataSource 提供表情组时会自动 `configure(groups:)` 并下发给面板。
public final class EmotionHelper {

    // MARK: - 配置数据

    /// 展平后的「写入输入框」表情列表（含 Image）；变更会清空缓存字典
    public var emotionArray: [Emotion] = [] {
        didSet {
            imageDictionary = nil
            attributedCache.removeAll(keepingCapacity: false)
            _ = ensureImageDictionary()
        }
    }

    // MARK: - 内部状态

    /// displayName → Image
    private var imageDictionary: [String: UIImage]?
    /// AttributedString 缓存：`[微笑]17` → 附件串
    private var attributedCache: [String: NSAttributedString] = [:]
    /// 匹配 `[...]` 的正则
    private let regularExpression: NSRegularExpression

    // MARK: - 初始化

    /// 创建空映射表的 helper；随后调用 `configure` 注入表情
    public init() {
        // 惰性编译 `[...]` 匹配正则（中文 / 英数字 key）
        regularExpression = try! NSRegularExpression(pattern: "\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]", options: [])
    }

    // MARK: - 配置

    /// 用多组表情配置映射表（只收「写入输入框」的组，自定义直发贴纸不参与图文互转）
    /// - Parameter groups: 业务表情组
    public func configure(groups: [EmotionGroup]) {
        emotionArray = groups
            .filter { $0.tapAction == .insertIntoInput }
            .flatMap(\.emotions)
    }

    /// 用单列表配置映射表
    /// - Parameter emotions: 表情列表
    public func configure(emotions: [Emotion]) {
        emotionArray = emotions
    }

    // MARK: - 图文互转

    /// 单表情 key → 附件 AttributedString
    /// - Parameters:
    ///   - imageKey: 如 `[微笑]`
    ///   - font: 字体（决定附件尺寸）
    ///   - useCache: 是否使用 AttributedString 缓存（iOS 15+ 解析整段时应传 false）
    /// - Returns: 附件字符串；未匹配返回空
    public func attributedString(imageKey: String, font: UIFont, useCache: Bool) -> NSAttributedString {
        // 整段解析路径禁用缓存，避免混排时缓存 key 不一致
        if !useCache {
            guard let image = ensureImageDictionary()[imageKey] else { return NSAttributedString() }
            return makeAttachmentString(imageKey: imageKey, image: image, font: font)
        }

        // 单 key 查询可走 pointSize 维度的缓存
        let cacheKey = String(format: "%@%.1f", imageKey, font.pointSize)
        if let cached = attributedCache[cacheKey] {
            return cached
        }

        guard let image = ensureImageDictionary()[imageKey] else { return NSAttributedString() }
        let result = makeAttachmentString(imageKey: imageKey, image: image, font: font)
        attributedCache[cacheKey] = result
        return result
    }

    /// 整段文本解析：`害~你好[微笑]` → 图文混排
    /// - Parameters:
    ///   - text: 纯文本
    ///   - font: 字体
    /// - Returns: 可变富文本
    public func attributedString(from text: String, font: UIFont) -> NSMutableAttributedString {
        let matches = regularExpression.matches(
            in: text,
            options: [.withTransparentBounds],
            range: NSRange(location: 0, length: (text as NSString).length)
        )

        let result = NSMutableAttributedString(string: text)
        let useCache = false

        // 从后往前替换，避免 range 因长度变化而错位
        for match in matches.reversed() {
            let key = (text as NSString).substring(with: match.range)
            let imageAttr = attributedString(imageKey: key, font: font, useCache: useCache)
            if imageAttr.length > 0 {
                result.replaceCharacters(in: match.range, with: imageAttr)
            }
        }

        // 统一段落字体（附件外的普通文字）
        result.addAttributes([.font: font], range: NSRange(location: 0, length: result.length))
        return result
    }

    /// 更新单个表情图片（异步出图完成后可调用）
    /// - Parameters:
    ///   - identifier: 表情 id
    ///   - image: 新图
    public func updateImage(_ image: UIImage?, forIdentifier identifier: String) {
        guard let index = emotionArray.firstIndex(where: { $0.identifier == identifier }) else { return }

        emotionArray[index].image = image
        // 图变更后失效字典与 Attributed 缓存
        imageDictionary = nil
        attributedCache.removeAll(keepingCapacity: false)
        _ = ensureImageDictionary()
    }

    // MARK: - 私有

    /// 惰性构建 displayName → UIImage 字典
    private func ensureImageDictionary() -> [String: UIImage] {
        // 已构建过直接复用
        if let imageDictionary { return imageDictionary }

        // 只收录带本地图的表情；无图的走面板异步加载，不进互转表
        var map: [String: UIImage] = [:]
        for emotion in emotionArray {
            if let image = emotion.image {
                map[emotion.displayName] = image
            }
        }

        imageDictionary = map
        return map
    }

    /// 构造带 `EmotionAttachment` 的单段 AttributedString
    private func makeAttachmentString(imageKey: String, image: UIImage, font: UIFont) -> NSAttributedString {
        let attachment = EmotionAttachment()
        // 还原纯文本时用 displayText（如 `[微笑]`）
        attachment.displayText = imageKey
        attachment.image = image

        // 与行高对齐，垂直偏移用 descender，避免表情相对基线偏上
        attachment.bounds = CGRect(x: 0, y: font.descender, width: font.lineHeight, height: font.lineHeight)
        return NSAttributedString(attachment: attachment)
    }
}