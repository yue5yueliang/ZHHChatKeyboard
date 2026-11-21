//
//  Emotion.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 单个表情数据模型（Emotion 模块）。
///
/// 职责：描述面板上一点对应的标识、插入 key、图片与无障碍文案。
/// 用法：
/// - `displayName`：插入与解析用的纯文本 key，须统一包裹符，如 `[微笑]`
/// - `image`：同步图；异步可先 nil，再经 `EmotionImageLoading` / `EmotionHelper.updateImage` 补图
/// - 库不内置可商用表情资源，图与文案均由业务注入
public struct Emotion: Equatable {

    // MARK: - 属性

    /// 表情标识，建议全局唯一
    public var identifier: String
    /// 插入文本 / 解析 key，须用统一左右包裹符，如 `[微笑]`
    public var displayName: String
    /// 同步图片；异步场景可先为 nil，再通过 `EmotionImageLoading` 补图
    public var image: UIImage?
    /// VoiceOver 文案；nil 时用去掉包裹符的 displayName
    public var accessibilityLabel: String?

    // MARK: - 初始化

    /// 创建表情
    /// - Parameters:
    ///   - identifier: 标识
    ///   - displayName: 展示/插入文本，如 `[微笑]`
    ///   - image: 图片（由业务提供）
    ///   - accessibilityLabel: 无障碍文案
    public init(identifier: String, displayName: String, image: UIImage? = nil, accessibilityLabel: String? = nil) {
        self.identifier = identifier
        self.displayName = displayName
        self.image = image
        self.accessibilityLabel = accessibilityLabel
    }

    // MARK: - 派生

    /// 无障碍标签（已处理默认值）
    public var resolvedAccessibilityLabel: String {
        // 业务显式提供了非空文案，优先使用
        if let accessibilityLabel, !accessibilityLabel.isEmpty {
            return accessibilityLabel
        }

        // 否则去掉 `[` `]` 包裹符作为读屏文案
        let trimmed = displayName.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        return trimmed.isEmpty ? displayName : trimmed
    }

    // MARK: - Equatable

    /// 以 identifier、displayName、accessibilityLabel 判断是否同一表情（不含 image，便于异步补图）
    public static func == (lhs: Emotion, rhs: Emotion) -> Bool {
        lhs.identifier == rhs.identifier
            && lhs.displayName == rhs.displayName
            && lhs.accessibilityLabel == rhs.accessibilityLabel
    }
}