//
//  ExtendBoardItem.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 扩展面板（「+」）单个入口模型（ExtendBoard 模块）。
///
/// 职责：描述一格入口的图标、标题与角标，由业务组装为 `ExtendBoardView.items`。
/// 用法：角标规则见 `badgeText`——`nil` 不显示；空字符串小红点；非空显示文字角标。
public struct ExtendBoardItem: Equatable {

    // MARK: - 属性

    /// 图标
    public var icon: UIImage?
    /// 标题（显示在卡片下方）
    public var title: String
    /// 角标：`nil` 不显示；空字符串显示小红点；非空显示文字角标
    public var badgeText: String?

    // MARK: - 初始化

    /// 创建扩展入口
    /// - Parameters:
    ///   - icon: 入口图标
    ///   - title: 入口标题
    ///   - badgeText: 角标文案；见 `badgeText` 属性说明
    public init(icon: UIImage?, title: String, badgeText: String? = nil) {
        self.icon = icon
        self.title = title
        self.badgeText = badgeText
    }
}