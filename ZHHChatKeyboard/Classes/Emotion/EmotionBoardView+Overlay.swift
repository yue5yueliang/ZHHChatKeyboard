//
//  EmotionBoardView+Overlay.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 遮罩透明度 / 异步出图

extension EmotionBoardView {

    /// 删/发浮层下方的表情格降低 alpha 并禁用点击，避免与按钮抢占触摸
    func adjustEmotionsAlpha() {
        guard let pageView = currentPageView() else { return }
        let grid = pageView.collectionView
        let layout = pageView.gridLayout

        // 当前页没有删/发（如 GIF 组 / page 未就绪）：恢复可点，不做遮罩
        let buttonsOnCurrentPage = actionButtonsPageIndex == selectedGroupIndex
            && actionButtonsView.superview === pageView
            && !actionButtonsView.isHidden
            && pageView.bounds.width > 1
            && actionButtonsView.bounds.width > 1
        guard buttonsOnCurrentPage else {
            for cell in grid.visibleCells {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cell.alpha = 1
                CATransaction.commit()
                cell.isUserInteractionEnabled = true
            }
            return
        }

        // 删/发在面板坐标系下的包围盒
        let deleteFrame = actionButtonsView.convert(deleteButton.frame, to: self)
        let sendFrame = actionButtonsView.convert(sendButton.frame, to: self)
        let buttonGroupRect = CGRect(
            x: min(deleteFrame.minX, sendFrame.minX),
            y: min(deleteFrame.minY, sendFrame.minY),
            width: max(deleteFrame.maxX, sendFrame.maxX) - min(deleteFrame.minX, sendFrame.minX),
            height: max(deleteFrame.maxY, sendFrame.maxY) - min(deleteFrame.minY, sendFrame.minY)
        )
        guard buttonGroupRect.width > 0, buttonGroupRect.height > 0, layout.columns > 0 else { return }

        // 转到网格坐标系，按列/行估算被按钮挡住的格子范围
        let floatingRect = grid.convert(buttonGroupRect, from: self)
        let columns = layout.columns
        let emotionSize = layout.emotionSize
        let rowHeight = layout.itemSize.height + layout.lineSpacing
        let insetLeft = grid.contentInset.left
        let insetTop = grid.contentInset.top
        let columnIndexLeft = Int(ceil((floatingRect.minX - insetLeft) / max(emotionSize.width + layout.horizontalGap, 1))) - 1
        let columnIndexRight = columns - 1
        let rowIndexTop = (floatingRect.minY - insetTop) / max(rowHeight, 1) - 1

        // 逐格：与按钮区相交则渐变 alpha，完全在下方则透明
        for cell in grid.visibleCells {
            guard
                let emotionCell = cell as? EmotionCollectionCell,
                let indexPath = grid.indexPath(for: cell)
            else { continue }

            // 行列下标，并判断是否落在删/发遮罩列范围内
            let row = indexPath.item / columns
            let column = indexPath.item % columns
            let underButtons = column >= columnIndexLeft && column <= columnIndexRight && CGFloat(row) > rowIndexTop

            if underButtons {
                if row == Int(ceil(rowIndexTop)) {
                    // 临界行：按与按钮区重叠高度算二次曲线透明度
                    let emotionFrame = emotionCell.convert(emotionCell.emotionImageFrame, to: grid)
                    let intersectAreaHeight = floatingRect.minY - emotionFrame.minY
                    let percent = intersectAreaHeight / max(emotionSize.height, 1)
                    let opacity = max(0, min(1, percent * percent))

                    // 关隐式动画，避免滚动时闪烁
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    emotionCell.alpha = opacity
                    CATransaction.commit()
                    emotionCell.isUserInteractionEnabled = opacity > 0.05
                } else {
                    // 完全被按钮挡住：隐藏且不可点
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    emotionCell.alpha = 0
                    CATransaction.commit()
                    emotionCell.isUserInteractionEnabled = false
                }
            } else {
                // 未遮挡：全显可点
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                emotionCell.alpha = 1
                CATransaction.commit()
                emotionCell.isUserInteractionEnabled = true
            }
        }
    }

    /// 同步读图：模型内建图 → 面板缓存 → nil
    func image(for emotion: Emotion) -> UIImage? {
        if let image = emotion.image { return image }
        if let cached = cachedImages[emotion.identifier] { return cached }
        return nil
    }

    /// 无本地图时经 `imageLoader` 异步加载，主线程写缓存并刷新可见 cell
    func requestImageIfNeeded(for emotion: Emotion, in pageView: EmotionGroupPageView, at indexPath: IndexPath) {
        let id = emotion.identifier

        // 已有图 / 缓存 / 加载中 / 失败过 / 无 loader：跳过
        guard
            emotion.image == nil,
            cachedImages[id] == nil,
            !loadingImageIdentifiers.contains(id),
            !failedImageIdentifiers.contains(id),
            let imageLoader
        else { return }

        // 标记加载中，防并发重复请求
        loadingImageIdentifiers.insert(id)
        imageLoader.emotionBoardView(self, loadImageFor: emotion) { [weak self, weak pageView] image in
            DispatchQueue.main.async {
                guard let self, let pageView else { return }
                self.loadingImageIdentifiers.remove(id)

                if let image {
                    // 入缓存，并同步 EmotionHelper；可见则刷新该格
                    self.cachedImages[id] = image
                    self.emotionHelper.updateImage(image, forIdentifier: id)
                    if pageView.collectionView.indexPathsForVisibleItems.contains(indexPath) {
                        pageView.collectionView.reloadItems(at: [indexPath])
                    }
                } else {
                    // 失败记入集合，本会话不再重试
                    self.failedImageIdentifiers.insert(id)
                }
            }
        }
    }
}
