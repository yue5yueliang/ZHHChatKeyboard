//
//  EmotionGroup.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/16.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 展示与交互枚举

/// 表情组展示风格（影响默认绘制尺寸；小表情统一一档，列数再按屏宽算）
public enum EmotionGroupStyle: Equatable {
    /// 默认小表情网格，34×34
    case emoji
    /// 自定义贴纸 / GIF 大图网格，约 64×64
    case sticker
    /// 自定义尺寸
    case custom(CGSize)

    /// 该风格对应的表情绘制尺寸
    public var emotionSize: CGSize {
        switch self {
        case .emoji:
            return CGSize(width: 34, height: 34)
        case .sticker:
            return CGSize(width: 64, height: 64)
        case .custom(let size):
            return size
        }
    }
}

/// 点击表情后的业务动作
public enum EmotionTapAction: Equatable {
    /// 写入输入框（默认小表情）；该组页面会挂删/发按钮
    case insertIntoInput
    /// 直接发送（自定义贴纸 / GIF 等）；不挂删/发
    case sendDirectly
}

// MARK: - EmotionGroup

/// 一套表情 / 贴纸组（对应表情面板顶部一个 Tab）。
///
/// 职责：描述 Tab 元数据、网格风格、点选动作与组内 `Emotion` 列表。
/// 用法：`style` 影响默认格子尺寸；`tapAction` 决定点选后写入输入框还是直接发送。
/// 未显式传 `tapAction` 时：`.emoji` → 写入输入框，`.sticker` → 直发。
public struct EmotionGroup {

    // MARK: - 属性

    /// 组标识（业务侧去重 / 缓存用）
    public var identifier: String
    /// Tab 标题（无 `icon` 时显示文字）
    public var title: String
    /// Tab 图标（有则优先于标题）
    public var icon: UIImage?

    /// 展示风格（决定默认 `emotionSize`）
    public var style: EmotionGroupStyle
    /// 点击动作：默认组写入输入框；自定义贴纸 / GIF 直接发送
    public var tapAction: EmotionTapAction

    /// 组内表情列表
    public var emotions: [Emotion]

    /// 是否在网格首格显示「添加」按钮（自定义表情常用）
    public var showsAddButton: Bool
    /// 是否在每个表情下方显示名称（贴纸默认不显示）
    public var showsItemTitles: Bool

    // MARK: - 初始化

    /// 创建表情组
    /// - Parameters:
    ///   - identifier: 组唯一标识
    ///   - title: Tab 标题
    ///   - icon: Tab 图标，默认 nil（显示文字）
    ///   - style: 默认 `.emoji`；自定义贴纸 / GIF 用 `.sticker`
    ///   - tapAction: 默认随 style——`.emoji` 写入输入框，`.sticker` 直接发送；可显式覆盖
    ///   - emotions: 组内表情
    ///   - showsAddButton: 首格加号，默认 false
    ///   - showsItemTitles: cell 下方文案，默认 false
    public init(
        identifier: String,
        title: String,
        icon: UIImage? = nil,
        style: EmotionGroupStyle = .emoji,
        tapAction: EmotionTapAction? = nil,
        emotions: [Emotion],
        showsAddButton: Bool = false,
        showsItemTitles: Bool = false
    ) {
        // Tab 元数据
        self.identifier = identifier
        self.title = title
        self.icon = icon
        self.style = style

        // tapAction：显式传入优先；否则贴纸风格默认直发，其余写入输入框
        switch tapAction {
        case .some(let action):
            self.tapAction = action
        case .none:
            if case .sticker = style {
                self.tapAction = .sendDirectly
            } else {
                self.tapAction = .insertIntoInput
            }
        }

        // 网格内容与展示开关
        self.emotions = emotions
        self.showsAddButton = showsAddButton
        self.showsItemTitles = showsItemTitles
    }
}

// MARK: - 数据源协议

/// 表情面板数据源：多组由业务注入，库不内置商用表情
public protocol EmotionDataSource: AnyObject {
    /// 表情组数量
    func numberOfGroups(in boardView: EmotionBoardView) -> Int
    /// 指定下标的表情组
    func emotionBoardView(_ boardView: EmotionBoardView, groupAt index: Int) -> EmotionGroup
}

public extension EmotionDataSource {
    /// 展平全部表情（供 EmotionHelper 图文互转）
    func allEmotions(in boardView: EmotionBoardView) -> [Emotion] {
        (0..<numberOfGroups(in: boardView)).flatMap {
            emotionBoardView(boardView, groupAt: $0).emotions
        }
    }
}

// MARK: - 静态数据源

/// 基于数组的表情数据源（弱引用 `dataSource` 时由面板强持有 `retainedDataSource`）
public final class StaticEmotionDataSource: EmotionDataSource {

    /// 全部表情组（可热更新后由面板 `reloadData`）
    public var groups: [EmotionGroup]

    /// - Parameter groups: 业务注入的表情组列表
    public init(groups: [EmotionGroup]) {
        self.groups = groups
    }

    /// 返回 `groups.count`
    public func numberOfGroups(in boardView: EmotionBoardView) -> Int {
        groups.count
    }

    /// 按下标取组（调用方需保证 index 合法）
    public func emotionBoardView(_ boardView: EmotionBoardView, groupAt index: Int) -> EmotionGroup {
        groups[index]
    }
}

// MARK: - 异步出图

/// 异步出图：`Emotion.image == nil` 时由面板经 `imageLoader` 请求加载
public protocol EmotionImageLoading: AnyObject {
    /// 为某个表情加载图片，完成后回调（可在任意队列回调，面板会切回主线程刷新）
    /// - Parameters:
    ///   - boardView: 发起请求的表情面板
    ///   - emotion: 待出图的表情
    ///   - completion: 成功传图，失败传 nil（面板会记入失败集合，本会话不再重试）
    func emotionBoardView(_ boardView: EmotionBoardView, loadImageFor emotion: Emotion, completion: @escaping (UIImage?) -> Void)
}
