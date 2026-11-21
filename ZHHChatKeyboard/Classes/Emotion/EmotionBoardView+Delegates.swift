//
//  EmotionBoardView+Delegates.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - ChatKeyboardPageViewDelegate

extension EmotionBoardView: ChatKeyboardPageViewDelegate {

    /// 横滑过半页时提前切换 Tab 选中态，并刷新删/发遮罩
    public func chatKeyboardPageView(_ contentView: ChatKeyboardPageView, didScrollFrom startIndex: Int, to endIndex: Int, progress: CGFloat) {
        // 过半页时提前切 Tab 选中态，手感更跟手
        if progress >= 0.5, groups.indices.contains(endIndex), endIndex != selectedGroupIndex {
            selectedGroupIndex = endIndex
            applyStyleForSelectedGroup()
            groupTabView.reloadData()
        }
        adjustEmotionsAlpha()
    }

    /// 减速落页后同步组选中（不再二次滚动分页）
    public func chatKeyboardPageView(_ contentView: ChatKeyboardPageView, didEndDeceleratingFrom startIndex: Int, to endIndex: Int) {
        selectGroup(at: endIndex, scrollPages: false)
    }

    /// 拖动结束：刷新遮罩（未进入减速时也要校正）
    public func chatKeyboardPageViewDidEndDragging(_ contentView: ChatKeyboardPageView) {
        adjustEmotionsAlpha()
    }
}

// MARK: - Tab CollectionView

extension EmotionBoardView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /// Tab 数量 = 表情组数
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        groups.count
    }

    /// 配置组 Tab：图标或标题 + 选中底色
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.groupCellId, for: indexPath) as! EmotionGroupTabCell
        let group = groups[indexPath.item]
        cell.configure(group: group, selected: indexPath.item == selectedGroupIndex, selectedBackgroundColor: tabSelectedBackgroundColor)
        return cell
    }

    /// 点 Tab：切组并带动画横滑分页
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectGroup(at: indexPath.item, scrollPages: true)
    }

    /// Tab 格尺寸：有图标 44×32，纯文字按标题宽估算
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let group = groups[indexPath.item]
        if group.icon != nil {
            return CGSize(width: 44, height: 32)
        }
        let text = group.title as NSString
        let width = ceil(text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 12)]).width) + 16
        return CGSize(width: max(44, width), height: 32)
    }
}
