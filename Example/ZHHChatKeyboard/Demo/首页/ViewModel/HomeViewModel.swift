//
//  HomeViewModel.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Foundation

/// 首页列表数据：按库能力分组（标准 / 胶囊 / 聊天 / 其他）
final class HomeViewModel {

    /// 全部分组
    private(set) var groups: [DemoSceneGroup] = DemoSceneGroup.allCases

    var numberOfSections: Int { groups.count }
}

// MARK: - 列表数据

extension HomeViewModel {

    func group(at section: Int) -> DemoSceneGroup? {
        guard groups.indices.contains(section) else { return nil }
        return groups[section]
    }

    func numberOfItems(in section: Int) -> Int {
        guard let group = group(at: section) else { return 0 }
        let count = group.scenes.count
        // 空分组仍显示一行占位，便于后续扩 Demo
        return count == 0 ? 1 : count
    }

    /// 取指定行场景；空分组占位返回 nil
    func item(at indexPath: IndexPath) -> DemoSceneKind? {
        guard let group = group(at: indexPath.section) else { return nil }
        let scenes = group.scenes
        guard scenes.indices.contains(indexPath.row) else { return nil }
        return scenes[indexPath.row]
    }

    /// 空分组占位文案
    func placeholderTitle(at section: Int) -> String? {
        guard let group = group(at: section), group.scenes.isEmpty else { return nil }
        return "即将添加"
    }
}
