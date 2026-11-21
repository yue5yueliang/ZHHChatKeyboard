//
//  ChatViewModel.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 聊天页消息数据
final class ChatViewModel {

    /// 消息列表
    private(set) var messages: [ChatMessage] = []
    /// 下一条消息自增 id
    private var nextId = 1

    /// 分组数
    var numberOfSections: Int { 1 }
}

// MARK: - 列表查询

extension ChatViewModel {

    /// 指定分组消息数
    /// - Parameter section: 分组下标
    /// - Returns: 消息条数
    func numberOfItems(in section: Int) -> Int {
        messages.count
    }

    /// 取指定行消息
    /// - Parameter indexPath: 行位置
    /// - Returns: 消息；越界返回 nil
    func item(at indexPath: IndexPath) -> ChatMessage? {
        guard messages.indices.contains(indexPath.row) else { return nil }
        return messages[indexPath.row]
    }
}

// MARK: - 数据变更

extension ChatViewModel {

    /// 加载示例对话
    func loadSample() {
        messages = [
            ChatMessage(id: nextId, text: "你好，这是 ZHHChatKeyboard Demo", isOutgoing: false),
            ChatMessage(id: nextId + 1, text: "试试表情 [微笑] 和扩展面板", isOutgoing: false)
        ]
        nextId = 100
    }

    /// 追加一条发出的消息
    /// - Parameter text: 发送文本
    /// - Returns: 新消息所在 IndexPath
    @discardableResult
    func appendOutgoing(_ text: String) -> IndexPath {
        let msg = ChatMessage(id: nextId, text: text, isOutgoing: true)
        nextId += 1
        messages.append(msg)
        return IndexPath(row: messages.count - 1, section: 0)
    }
}
