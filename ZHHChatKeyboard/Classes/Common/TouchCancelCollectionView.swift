//
//  TouchCancelCollectionView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/17.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 优化滚动手势的 `UICollectionView`（Common 模块）。
///
/// 职责：在 `UIControl`（如按钮、分页 Tab）上起滑时，允许取消控件触摸并交给 Collection 滚动。
/// 用法：搭配 `delaysContentTouches = false`，保证轻点立刻高亮、滑动不误触为点击。
/// 表情 Tab、扩展面板网格、`ChatKeyboardPageView` 均使用此类。
open class TouchCancelCollectionView: UICollectionView {

    // MARK: - 触摸

    /// 子视图若为 `UIControl`，滑动时应取消其对触摸的独占，以便开始滚动
    open override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIControl { return true }
        return super.touchesShouldCancel(in: view)
    }
}