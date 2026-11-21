//
//  EmotionGridLayout.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 表情网格布局结果

/// 表情网格一次排布结果：边距、cell 尺寸、列数、行列间距
struct EmotionGridLayout {
    /// CollectionView 内容边距
    var contentInset: UIEdgeInsets
    /// cell 尺寸；贴纸含底部名称时高度大于宽度
    var itemSize: CGSize
    /// 列数
    var columns: Int
    /// 列间距
    var horizontalGap: CGFloat
    /// 行间距
    var lineSpacing: CGFloat
    /// 图片绘制区域尺寸（不含名称）
    var emotionSize: CGSize
    /// 是否在 cell 底部显示名称
    var showsTitle: Bool
}