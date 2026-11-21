//
//  DemoSceneKind.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 首页分组（对齐库：标准 / 胶囊 / 聊天场景 / 其他）
enum DemoSceneGroup: Int, CaseIterable {
    /// `ChatInputBarLayoutStyle.standard`
    case standard
    /// `ChatInputBarLayoutStyle.capsule`（左 / 右语音位）
    case capsule
    /// 会话类页面（列表滚底、朋友圈评论等）
    case chat
    /// 非常驻、工具条、主题等其它形态
    case other

    var title: String {
        switch self {
        case .standard: return "标准"
        case .capsule: return "胶囊"
        case .chat: return "聊天"
        case .other: return "其他"
        }
    }

    /// 该分组下的 Demo
    var scenes: [DemoSceneKind] {
        switch self {
        case .standard:
            return [.common, .commonCustomBoard]
        case .capsule:
            return [.capsuleLeading, .capsuleTrailing]
        case .chat:
            return [.chat, .moments]
        case .other:
            return [.submit, .pageTextField, .darkMode]
        }
    }
}

/// 入口场景类型
enum DemoSceneKind: Int, CaseIterable {
    /// 标准 · 常驻输入栏（顶部开关可配按钮）
    case common
    /// 标准 · 自定义面板
    case commonCustomBoard
    /// 胶囊 · 语音在左（`capsuleLeading`）
    case capsuleLeading
    /// 胶囊 · 语音在右（`capsuleTrailing`）
    case capsuleTrailing
    /// 聊天列表（contentInset 滚底，推荐写法）
    case chat
    /// 朋友圈（默认隐藏；页内可切换常驻）
    case moments
    /// 自定义评论栏（默认隐藏；点按钮再弹出）
    case submit
    /// 页面 TextField + 键盘上方工具条
    case pageTextField
    /// 深色模式演示
    case darkMode
}

// MARK: - 展示文案

extension DemoSceneKind {

    /// 列表主标题
    var title: String {
        switch self {
        case .common: return "常驻输入栏"
        case .commonCustomBoard: return "自定义面板"
        case .capsuleLeading: return "语音在左"
        case .capsuleTrailing: return "语音在右"
        case .chat: return "聊天列表"
        case .moments: return "朋友圈评论"
        case .submit: return "自定义评论栏"
        case .pageTextField: return "页面 TextField + 工具条"
        case .darkMode: return "深色模式演示"
        }
    }

    /// 列表副标题
    var subtitle: String {
        switch self {
        case .common: return "layoutStyle.standard；输入框下回复 / 高度回调等开关"
        case .commonCustomBoard: return "DataSource 返回自建 UIView 面板"
        case .capsuleLeading: return "capsuleLeading；上方快捷短语 + 胶囊内回复"
        case .capsuleTrailing: return "capsuleTrailing；语音 / 表情 / + 全在右侧"
        case .chat: return "推荐：contentInset 避开输入区，键盘弹起滚到底"
        case .moments: return "默认隐藏；右上角可切换常驻 / 隐藏"
        case .submit: return "默认隐藏；点「写评论」弹出输入框 + 工具行 + 快捷表情"
        case .pageTextField: return "输入在页面；键盘上挂无输入框工具条"
        case .darkMode: return "跟随系统 Dark Mode"
        }
    }
}
