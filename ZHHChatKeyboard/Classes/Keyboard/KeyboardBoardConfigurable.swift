//
//  KeyboardBoardConfigurable.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/21.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 表情面板可灌数据协议（`KeyboardManager` 只依赖协议，不绑死具体 View 类型）
public protocol EmotionBoardConfigurable: AnyObject {
    /// 与会话共用的图文互转 helper
    var emotionHelper: EmotionHelper { get set }
    /// 用表情组刷新面板
    func update(groups: [EmotionGroup])
}

/// 「更多」面板可灌数据协议
public protocol ExtendBoardConfigurable: AnyObject {
    /// 用入口列表刷新面板
    func update(items: [ExtendBoardItem])
}

extension EmotionBoardView: EmotionBoardConfigurable {}

extension ExtendBoardView: ExtendBoardConfigurable {}
