//
//  MomentsViewModel.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 朋友圈动态列表数据
final class MomentsViewModel {

    /// 动态文案列表
    private(set) var posts = (1...20).map { "动态内容 #\($0) —— 点击后评论" }
}

// MARK: - 列表查询

extension MomentsViewModel {

    /// 动态条数
    func numberOfItems() -> Int {
        posts.count
    }

    /// 取指定行动态文案
    /// - Parameter index: 行下标
    /// - Returns: 文案
    func item(at index: Int) -> String {
        posts[index]
    }
}

// MARK: - 数据变更

extension MomentsViewModel {

    /// 在顶部插入一条「我」发出的评论 / 回复
    /// - Parameter text: 发送文本
    func insertOutgoing(_ text: String) {
        posts.insert("我：\(text)", at: 0)
    }
}
