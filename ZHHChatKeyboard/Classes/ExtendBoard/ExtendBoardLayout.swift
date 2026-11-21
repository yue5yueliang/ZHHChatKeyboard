//
//  ExtendBoardLayout.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - Layout

/// 按页摆放入口：列宽均分屏宽；行高用内容高 + 固定行距，整块垂直居中
final class ExtendBoardLayout: UICollectionViewLayout {

    // MARK: - 布局参数

    /// 入口总数
    var itemCount = 0
    /// 单行内容高度（卡片 + 标题）
    var itemContentHeight: CGFloat = 83
    /// 每页列数（手机 4 / iPad 10）
    var perRow = 4
    /// 每页行数
    var perColumnCount = 2
    /// 行间距
    var rowSpacing: CGFloat = 18

    // MARK: - 缓存

    /// 全部 cell 的布局属性缓存
    private var attributesList: [UICollectionViewLayoutAttributes] = []
    /// 横向可滚 contentSize
    private var contentSize: CGSize = .zero

    // MARK: - 布局计算

    /// 按当前 itemCount 与 bounds 重算全部 cell frame 与 contentSize
    override func prepare() {
        super.prepare()
        attributesList.removeAll(keepingCapacity: true)
        contentSize = .zero

        guard let collectionView, itemCount > 0 else { return }
        let pageW = collectionView.bounds.width
        let pageH = collectionView.bounds.height
        guard pageW > 0, pageH > 0 else { return }

        let columns = max(1, perRow)
        let rows = max(1, perColumnCount)
        let perPage = columns * rows
        let pageCount = Int(ceil(Double(itemCount) / Double(perPage)))

        // 列宽均分：不再固定 cell 宽再倒推间距
        let columnW = pageW / CGFloat(columns)
        let gridH = CGFloat(rows) * itemContentHeight + CGFloat(max(0, rows - 1)) * rowSpacing
        // 网格垂直居中；至少留 12pt 顶边
        let topInset = max(12, (pageH - gridH) / 2)

        for index in 0..<itemCount {
            let page = index / perPage
            let indexInPage = index % perPage
            let row = indexInPage / columns
            let col = indexInPage % columns

            let x = CGFloat(page) * pageW + CGFloat(col) * columnW
            let y = topInset + CGFloat(row) * (itemContentHeight + rowSpacing)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attributes.frame = CGRect(x: x, y: y, width: columnW, height: itemContentHeight)
            attributesList.append(attributes)
        }

        contentSize = CGSize(width: pageW * CGFloat(pageCount), height: pageH)
    }

    // MARK: - 布局查询

    /// 横向总宽度 = 页数 × 单页宽
    override var collectionViewContentSize: CGSize { contentSize }

    /// 返回与 `rect` 相交的已缓存 attributes
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attributesList.filter { $0.frame.intersects(rect) }
    }

    /// 按下标取单个 item 的 attributes
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard attributesList.indices.contains(indexPath.item) else { return nil }
        return attributesList[indexPath.item]
    }

    /// 仅尺寸变化时失效布局，offset 变化不重算
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return false }
        return collectionView.bounds.size != newBounds.size
    }
}