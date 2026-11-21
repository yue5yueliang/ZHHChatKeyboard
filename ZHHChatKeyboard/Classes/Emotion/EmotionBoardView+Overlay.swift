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

        // 按钮约束刚装上时强制出 frame，避免首次进板按零尺寸算成「无遮罩」
        ensureActionButtonsLayout(on: pageView)
        updateActionButtonsVeil()

        guard isActionButtonsOverlayActive(on: pageView) else {
            for cell in grid.visibleCells {
                setEmotionCell(cell, alpha: 1, interactive: true)
            }
            return
        }

        for cell in grid.visibleCells {
            guard let indexPath = grid.indexPath(for: cell) else { continue }
            applyEmotionOverlayAlpha(to: cell, at: indexPath, in: pageView)
        }
    }

    /// 单格同步压遮罩：扩区保底不漏 + 按露出高度连续渐隐；必须瞬间到位，禁止先亮再暗
    func applyEmotionOverlayAlpha(to cell: UICollectionViewCell, at indexPath: IndexPath, in pageView: EmotionGroupPageView) {
        ensureActionButtonsLayout(on: pageView)

        guard isActionButtonsOverlayActive(on: pageView) else {
            setEmotionCell(cell, alpha: 1, interactive: true)
            return
        }

        let layout = pageView.gridLayout
        let columns = layout.columns
        guard columns > 0 else {
            setEmotionCell(cell, alpha: 1, interactive: true)
            return
        }
        guard let floatingRect = actionButtonsFloatingRect(in: pageView.collectionView) else {
            setEmotionCell(cell, alpha: 1, interactive: true)
            return
        }

        let colPitch = layout.itemSize.width + layout.horizontalGap
        let rowPitch = layout.itemSize.height + layout.lineSpacing
        guard colPitch > 1, rowPitch > 1 else {
            setEmotionCell(cell, alpha: 1, interactive: true)
            return
        }

        // 水平仍按 QK：只压删发右侧若干列
        let columnIndexLeft = Int(ceil(floatingRect.minX / colPitch)) - 1
        let column = indexPath.item % columns
        guard column >= columnIndexLeft, column <= columns - 1 else {
            setEmotionCell(cell, alpha: 1, interactive: true)
            return
        }

        // 垂直用几何连续算：临界带二次曲线，完全落入 → 0（不漏）
        let row = indexPath.item / columns
        let cellFrame = pageView.collectionView.layoutAttributesForItem(at: indexPath)?.frame
            ?? CGRect(
                x: CGFloat(column) * colPitch,
                y: CGFloat(row) * rowPitch,
                width: layout.itemSize.width,
                height: layout.itemSize.height
            )

        let intersection = cellFrame.intersection(floatingRect)
        guard !intersection.isNull, intersection.width > 0.5, intersection.height > 0.5 else {
            setEmotionCell(cell, alpha: 1, interactive: true)
            return
        }

        let emotionH = max(layout.emotionSize.height, 1)
        let above = floatingRect.minY - cellFrame.minY
        if above <= 0 {
            setEmotionCell(cell, alpha: 0, interactive: false)
            return
        }

        let percent = min(1, above / emotionH)
        let opacity = percent * percent
        setEmotionCell(cell, alpha: opacity, interactive: opacity > 0.05)
    }

    /// 当前页是否应启用删/发遮罩
    func isActionButtonsOverlayActive(on pageView: EmotionGroupPageView) -> Bool {
        actionButtonsPageIndex == selectedGroupIndex
            && actionButtonsView.superview === pageView
            && !actionButtonsView.isHidden
            && pageView.bounds.width > 1
            && actionButtonsView.bounds.width > 1
    }

    /// 装约束后立刻算出删/发真实 frame（进板首帧必需）
    func ensureActionButtonsLayout(on pageView: EmotionGroupPageView) {
        guard actionButtonsView.superview === pageView else { return }
        pageView.layoutIfNeeded()
        actionButtonsView.layoutIfNeeded()
    }

    /// 删发遮罩矩形（网格坐标系）：整块容器（含安全区）扩到可见右下，底排绝对不漏
    func actionButtonsFloatingRect(in grid: UICollectionView) -> CGRect? {
        guard actionButtonsView.bounds.width > 1, actionButtonsView.bounds.height > 1 else { return nil }

        var rect = actionButtonsView.convert(actionButtonsView.bounds, to: grid)
        guard rect.width > 0, rect.height > 0 else { return nil }

        let visibleMaxX = grid.contentOffset.x + grid.bounds.width
        let visibleMaxY = grid.contentOffset.y + grid.bounds.height
        rect.size.width = max(rect.width, visibleMaxX - rect.minX)
        rect.size.height = max(rect.height, visibleMaxY - rect.minY)
        return rect
    }

    /// 容器顶边柔光罩：上沿透明 → 下沿贴近面板色，挡住安全区漏光，同时软化灰块硬边
    func updateActionButtonsVeil() {
        let veil = actionButtonsVeilLayer
        veil.frame = actionButtonsView.bounds
        let top = UIColor.clear.cgColor
        let mid = boardBackgroundColor.withAlphaComponent(0.35).resolvedColor(with: traitCollection).cgColor
        let bottom = boardBackgroundColor.withAlphaComponent(0.92).resolvedColor(with: traitCollection).cgColor
        veil.colors = [top, mid, bottom]
        veil.locations = [0, 0.4, 1]
    }

    /// 关隐式动画写 alpha，避免滚动 / 切板「先亮再暗」
    func setEmotionCell(_ cell: UICollectionViewCell, alpha: CGFloat, interactive: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cell.alpha = alpha
        CATransaction.commit()
        cell.isUserInteractionEnabled = interactive
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

        guard
            emotion.image == nil,
            cachedImages[id] == nil,
            !loadingImageIdentifiers.contains(id),
            !failedImageIdentifiers.contains(id),
            let imageLoader
        else { return }

        loadingImageIdentifiers.insert(id)
        imageLoader.emotionBoardView(self, loadImageFor: emotion) { [weak self, weak pageView] image in
            DispatchQueue.main.async {
                guard let self, let pageView else { return }
                self.loadingImageIdentifiers.remove(id)

                if let image {
                    self.cachedImages[id] = image
                    self.emotionHelper.updateImage(image, forIdentifier: id)
                    if pageView.collectionView.indexPathsForVisibleItems.contains(indexPath) {
                        pageView.collectionView.reloadItems(at: [indexPath])
                    }
                } else {
                    self.failedImageIdentifiers.insert(id)
                }
            }
        }
    }
}
