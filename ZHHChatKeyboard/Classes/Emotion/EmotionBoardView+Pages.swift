//
//  EmotionBoardView+Pages.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 页面构建 / 布局 / 切组

extension EmotionBoardView {

    /// 按 `groups` 重建各页 View，注入 `ChatKeyboardPageView` 并挂载删/发容器
    func rebuildPageViews() {
        // 先摘掉删/发容器，避免旧 page 残留引用
        actionButtonsView.removeFromSuperview()

        // 删/发只挂在 tapAction == .insertIntoInput 的那一组
        actionButtonsPageIndex = groups.firstIndex(where: { $0.tapAction == .insertIntoInput })

        // 一组一页：配网格，并在目标页挂上删/发
        groupPageViews = groups.indices.map { index in
            let page = EmotionGroupPageView()
            configurePageView(page, at: index)
            if index == actionButtonsPageIndex {
                page.addSubview(actionButtonsView)
            }
            return page
        }

        // 交给分页容器，并恢复当前选中组
        pageContentView.reload(pageViews: groupPageViews)
        pageContentView.currentIndex = selectedGroupIndex
        layoutActionButtonsIfNeeded()
    }

    /// 根据面板宽度、内边距、列数策略计算网格 `EmotionGridLayout`
    func makeEmotionGridLayout(
        boardWidth: CGFloat,
        emotionSize: CGSize,
        bottomExtra: CGFloat,
        padding: UIEdgeInsets,
        preferredGap: CGFloat,
        verticalSpacing: CGFloat,
        fixedColumns: Int? = nil,
        showsTitle: Bool = false,
        titleHeight: CGFloat = 0
    ) -> EmotionGridLayout {
        let emotionW = emotionSize.width
        let emotionH = emotionSize.height

        // 图片区取正方形边长（固定列数时再按屏宽重算）
        var side = max(emotionW, emotionH)
        // 需要标题时，cell 高度 = 图片边长 + 标题高
        let titleH = showsTitle ? max(0, titleHeight) : 0
        func itemSize(forImageSide imageSide: CGFloat) -> CGSize {
            CGSize(width: imageSide, height: imageSide + titleH)
        }

        // 宽度或尺寸无效：退回最小可用布局，避免除零
        guard boardWidth > 0, side > 0 else {
            let imageSize = CGSize(width: side, height: side)
            var inset = padding
            inset.bottom += bottomExtra
            return EmotionGridLayout(
                contentInset: inset,
                itemSize: itemSize(forImageSide: side),
                columns: max(1, fixedColumns ?? 1),
                horizontalGap: 0,
                lineSpacing: verticalSpacing,
                emotionSize: imageSize,
                showsTitle: showsTitle
            )
        }

        // 三种策略：固定列数 / 自适应无间距 / 自适应有间距
        let columns: Int
        let horizontalGap: CGFloat
        let insetLeft: CGFloat
        let insetRight: CGFloat

        if let fixed = fixedColumns, fixed > 0 {
            // 列数已给定（小表情 7/8，贴纸 5）：先扣左右 padding，再在剩余宽度里排 cell
            columns = fixed
            let available = max(0, boardWidth - padding.left - padding.right)

            if preferredGap <= 0 {
                // 无列间距：side = available / columns
                side = ChatKeyboardCommon.pixelRound(available / CGFloat(columns))
                horizontalGap = 0
            } else {
                // 有列间距：available = columns * side + (columns - 1) * gap
                // 故 side = (available - (columns - 1) * gap) / columns
                let gap = preferredGap
                side = ChatKeyboardCommon.pixelRound((available - CGFloat(columns - 1) * gap) / CGFloat(columns))
                horizontalGap = gap
            }

            // 左右边距固定为 padding，像素取整产生的余量留在内容区右侧，不改 inset
            insetLeft = padding.left
            insetRight = padding.right
        } else if preferredGap <= 0 {
            // 列数未定时且无间距：在扣除左右 padding 后的宽度里，按 side 估算能排几列
            let available = max(0, boardWidth - padding.left - padding.right)
            columns = max(1, Int(floor(available / side)))
            horizontalGap = 0
            insetLeft = padding.left
            insetRight = padding.right
        } else {
            // 列数未定时且有间距：用 side 估算列数，并把左右边距做成与列间距相同
            // 目标：boardWidth = columns * side + (columns + 1) * gap
            let minGap = min(12, preferredGap)
            func gap(for columnCount: Int) -> CGFloat {
                (boardWidth - CGFloat(columnCount) * side) / CGFloat(columnCount + 1)
            }

            var cols = max(1, Int((boardWidth + preferredGap) / (side + preferredGap)))
            var hGap = gap(for: cols)

            // 间距过小则减列，避免挤在一起
            while cols > 1 && hGap < minGap {
                cols -= 1
                hGap = gap(for: cols)
            }

            // 间距过大则尝试减列，使 gap 更接近 preferredGap
            while cols > 1 && hGap > preferredGap * 1.8 {
                let next = cols - 1
                let nextGap = gap(for: next)
                if abs(nextGap - preferredGap) < abs(hGap - preferredGap) {
                    cols = next
                    hGap = nextGap
                } else {
                    break
                }
            }

            columns = cols
            horizontalGap = hGap
            // 左右 inset 与列间距一致，视觉更匀
            insetLeft = hGap
            insetRight = hGap
        }

        // 汇总：正方形图片区 + 上下 inset（底含安全区等额外高度）
        let imageSize = CGSize(width: side, height: side)
        let insetTop = padding.top
        let insetBottom = padding.bottom + bottomExtra

        return EmotionGridLayout(
            contentInset: UIEdgeInsets(top: insetTop, left: insetLeft, bottom: insetBottom, right: insetRight),
            itemSize: itemSize(forImageSide: side),
            columns: columns,
            horizontalGap: horizontalGap,
            lineSpacing: max(0, verticalSpacing),
            emotionSize: imageSize,
            showsTitle: showsTitle
        )
    }

    /// 小表情列数：宽度 ≤ `emojiColumnsBreakpoint` 为 7，否则 8
    func emojiColumns(for boardWidth: CGFloat) -> Int {
        boardWidth <= emojiColumnsBreakpoint ? 7 : 8
    }

    /// 当前选中组对应的分页子 View
    func currentPageView() -> EmotionGroupPageView? {
        guard groupPageViews.indices.contains(selectedGroupIndex) else { return nil }
        return groupPageViews[selectedGroupIndex]
    }

    /// 切换选中组：刷新 Tab、可选横滑分页，并在下一 runloop 更新遮罩 alpha
    /// - Parameters:
    ///   - index: 目标组下标
    ///   - scrollPages: true 时带动画滚动 `pageContentView`
    func selectGroup(at index: Int, scrollPages: Bool) {
        guard groups.indices.contains(index) else { return }
        selectedGroupIndex = index
        applyStyleForSelectedGroup()
        groupTabView.reloadData()

        if groups.count > 1 {
            groupTabView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        }
        if scrollPages {
            pageContentView.setCurrentIndex(index, animated: true)
        }

        DispatchQueue.main.async { [weak self] in
            self?.adjustEmotionsAlpha()
        }
    }

    /// 为某一页计算网格布局并注入数据源、选中与滚动回调
    func configurePageView(_ page: EmotionGroupPageView, at index: Int) {
        guard groups.indices.contains(index) else { return }
        let group = groups[index]
        let size = group.style.emotionSize

        // 优先用分页区宽度；尚未布局时退回面板宽度
        let boardWidth = pageContentView.bounds.width > 0 ? pageContentView.bounds.width : bounds.width

        // 贴纸 vs 小表情：列数、边距、是否显示名称不同
        let isStickerLayout: Bool = {
            if case .sticker = group.style { return true }
            return false
        }()
        let showsTitle = isStickerLayout && group.showsItemTitles

        // 小表情：375 及以下 7 列，更宽 8 列；贴纸：固定 stickerColumns。列数定死后再均分边长。
        let columns = isStickerLayout ? stickerColumns : emojiColumns(for: boardWidth)
        let layout = makeEmotionGridLayout(
            boardWidth: boardWidth,
            emotionSize: size,
            bottomExtra: safeAreaInsets.bottom,
            padding: isStickerLayout ? stickerPaddingInPage : paddingInPage,
            preferredGap: cellSpacing,
            verticalSpacing: cellSpacing,
            fixedColumns: columns,
            showsTitle: showsTitle,
            titleHeight: showsTitle ? stickerTitleHeight : 0
        )

        // 闭包由面板持有，弱引用 self / page 避免循环引用
        page.configure(
            emotions: group.emotions,
            layout: layout,
            showsAddButton: group.showsAddButton,
            // 同步取图（模型 / 缓存）
            imageProvider: { [weak self] emotion in
                self?.image(for: emotion)
            },
            // 缺图时异步加载
            requestImage: { [weak self, weak page] emotion, indexPath in
                guard let self, let page else { return }
                self.requestImageIfNeeded(for: emotion, in: page, at: indexPath)
            },
            // 点表情 → delegate
            didSelect: { [weak self] emotionIndex in
                guard let self, self.groups.indices.contains(index) else { return }
                let group = self.groups[index]
                let emotion = group.emotions[emotionIndex]
                self.delegate?.emotionView(self, didSelect: emotion, at: emotionIndex, in: group)
            },
            // 点「添加」→ delegate
            didSelectAdd: { [weak self] in
                guard let self, self.groups.indices.contains(index) else { return }
                self.delegate?.emotionViewDidSelectAddButton(self, in: self.groups[index])
            },
            // 滚动 / 显示后刷新删发遮罩 alpha
            onScroll: { [weak self] in
                self?.adjustEmotionsAlpha()
            },
            onDisplay: { [weak self] in
                DispatchQueue.main.async { self?.adjustEmotionsAlpha() }
            }
        )
    }
}
