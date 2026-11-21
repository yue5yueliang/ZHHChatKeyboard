//
//  ChatKeyboardPageView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/18.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 横向分页内容区事件（默认空实现，按需覆写）
public protocol ChatKeyboardPageViewDelegate: AnyObject {
    /// 手指开始拖动分页
    func chatKeyboardPageViewWillBeginDragging(_ contentView: ChatKeyboardPageView)
    /// 手势滑动中的进度回调（程序化 `setCurrentIndex` / `reload` 不会回调）
    /// - Parameters:
    ///   - startIndex: 拖动起始页
    ///   - endIndex: 目标相邻页
    ///   - progress: 0～1，相对一页宽度的滑动比例
    func chatKeyboardPageView(_ contentView: ChatKeyboardPageView, didScrollFrom startIndex: Int, to endIndex: Int, progress: CGFloat)
    /// 减速结束，已落到某一页
    /// - Parameters:
    ///   - startIndex: 拖动起始页
    ///   - endIndex: 最终页
    func chatKeyboardPageView(_ contentView: ChatKeyboardPageView, didEndDeceleratingFrom startIndex: Int, to endIndex: Int)
    /// 拖动结束且不会继续减速（轻扫未触发减速时）
    func chatKeyboardPageViewDidEndDragging(_ contentView: ChatKeyboardPageView)
}

public extension ChatKeyboardPageViewDelegate {
    func chatKeyboardPageViewWillBeginDragging(_ contentView: ChatKeyboardPageView) {}
    func chatKeyboardPageView(_ contentView: ChatKeyboardPageView, didScrollFrom startIndex: Int, to endIndex: Int, progress: CGFloat) {}
    func chatKeyboardPageView(_ contentView: ChatKeyboardPageView, didEndDeceleratingFrom startIndex: Int, to endIndex: Int) {}
    func chatKeyboardPageViewDidEndDragging(_ contentView: ChatKeyboardPageView) {}
}

/// 横向分页内容容器（Common 模块；表情板等复用）。
///
/// 用法：
/// - 一组一页：用 `reload(pageViews:)` 注入各页 `UIView`，顺序即页序
/// - 左右滑切换；`currentIndex` / `setCurrentIndex` 默认无动画定位（避免内容晃）
/// - 手势进度走 `ChatKeyboardPageViewDelegate`；程序化切页不发 progress
/// - 底层为 `TouchCancelCollectionView` + 横向 paging FlowLayout
open class ChatKeyboardPageView: UIView {

    private static let cellId = "PageContentCell"

    /// 滑动 / 落页回调
    public weak var delegate: ChatKeyboardPageViewDelegate?

    /// 当前页索引；直接赋值时默认无动画、不通知 `didEndDecelerating`
    public var currentIndex: Int {
        get { _currentIndex }
        set { setCurrentIndex(newValue, notifyDelegate: false) }
    }

    /// 是否允许左右滑动，默认 true
    public var canScroll: Bool = true {
        didSet { collectionView.isScrollEnabled = canScroll }
    }

    /// 各页内容 View（强持有；顺序即页序）
    public private(set) var pageViews: [UIView] = []

    /// 底层横向分页 CollectionView（一页一个 item，itemSize = bounds）
    public private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = TouchCancelCollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.bounces = true
        view.alwaysBounceHorizontal = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.delaysContentTouches = false
        view.dataSource = self
        view.delegate = self
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.cellId)
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    // MARK: - 内部状态

    /// 当前页（与 `currentIndex` 同步）
    private var _currentIndex: Int = 0
    /// 程序化切页时为 true，忽略手势滑动进度回调
    private var isProgrammaticScroll = false
    /// `willBeginDragging` 时的 contentOffset.x，用于算 startIndex / progress
    private var startOffsetX: CGFloat = 0
    /// bounds 未就绪时推迟了 reload，待有尺寸后再刷（避免 zero itemSize 警告）
    private var pendingReload = false

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
    }

    /// - Parameters:
    ///   - frame: 初始 frame
    ///   - pageViews: 子页 View 列表
    ///   - delegate: 滑动回调
    public convenience init(frame: CGRect, pageViews: [UIView], delegate: ChatKeyboardPageViewDelegate? = nil) {
        self.init(frame: frame)
        self.delegate = delegate
        reload(pageViews: pageViews)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 布局

    open override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds

        // bounds 未就绪时不要写 itemSize={0,0}，否则 FlowLayout 会报警且内容空白
        guard bounds.width > 0, bounds.height > 0 else { return }

        // 一页一屏：itemSize 始终等于自身 bounds
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let size = bounds.size
            if layout.itemSize != size {
                layout.itemSize = size
                layout.invalidateLayout()
            }
        }

        // 此前因尺寸未就绪推迟的 reload，此时补刷
        if pendingReload {
            pendingReload = false
            collectionView.reloadData()
        }

        // bounds 变化后贴合当前页，避免 offset 错位抖动
        guard pageViews.indices.contains(_currentIndex) else { return }
        let targetX = CGFloat(_currentIndex) * bounds.width
        if abs(collectionView.contentOffset.x - targetX) > 0.5 {
            isProgrammaticScroll = true
            collectionView.setContentOffset(CGPoint(x: targetX, y: 0), animated: false)
            isProgrammaticScroll = false
        }
    }

    // MARK: - 公开 API

    /// 替换全部子页并刷新；尺寸未就绪时只记数据，等 `layoutSubviews` 再 reload
    public func reload(pageViews: [UIView]) {
        self.pageViews = pageViews

        // 页数变少时，当前索引不能越界
        if _currentIndex >= pageViews.count {
            _currentIndex = max(0, pageViews.count - 1)
        }

        // 尺寸未就绪时只记数据，等 layoutSubviews 再 reload，避免 zero itemSize 警告
        guard bounds.width > 0, bounds.height > 0 else {
            pendingReload = true
            setNeedsLayout()
            return
        }

        pendingReload = false
        collectionView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()

        // 刷新后无动画滚回当前页
        if pageViews.indices.contains(_currentIndex) {
            isProgrammaticScroll = true
            collectionView.scrollToItem(
                at: IndexPath(item: _currentIndex, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
            isProgrammaticScroll = false
        }
    }

    /// 指定当前页（不通知 `didEndDecelerating`，避免与 Tab 点击循环回调）
    /// - Parameters:
    ///   - index: 目标页
    ///   - animated: 是否动画（外部切页建议 false，避免内容左右晃）
    public func setCurrentIndex(_ index: Int, animated: Bool = false) {
        setCurrentIndex(index, animated: animated, notifyDelegate: false)
    }

    /// - Parameters:
    ///   - index: 目标页
    ///   - animated: 是否动画滚动
    ///   - notifyDelegate: true 时在页变化后回调 `didEndDecelerating`
    private func setCurrentIndex(_ index: Int, animated: Bool = false, notifyDelegate: Bool) {
        guard pageViews.indices.contains(index) else { return }

        let start = _currentIndex
        _currentIndex = index

        // 标记为程序化滚动，避免 didScroll 把手势进度回调出去
        isProgrammaticScroll = true
        collectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )

        // 无动画时立刻清标记；有动画则等 scrollViewDidEndScrollingAnimation
        if !animated {
            isProgrammaticScroll = false
        }

        if notifyDelegate, start != index {
            delegate?.chatKeyboardPageView(self, didEndDeceleratingFrom: start, to: index)
        }
    }
}

// MARK: - UICollectionViewDataSource / Delegate

extension ChatKeyboardPageView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /// 一页一个 item，数量等于 `pageViews.count`
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pageViews.count
    }

    /// 取出复用 cell，并把对应页 View 装进去
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellId, for: indexPath)
        installPage(at: indexPath.item, in: cell)
        return cell
    }

    /// 即将显示时再装一次页内容，兜住 cellForItem 时 bounds 未就绪的情况
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        installPage(at: indexPath.item, in: cell)
    }

    /// 每页尺寸 = CollectionView bounds；未就绪时暂用 1×1，真正尺寸在 `layoutSubviews` 校正
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = collectionView.bounds.size

        // bounds 未就绪时给 1×1，避免 FlowLayout zero size 警告
        if size.width > 0, size.height > 0 {
            return size
        }
        return CGSize(width: 1, height: 1)
    }

    /// 把对应 page 装进 cell；避免只靠 willDisplay 时 bounds 未就绪导致空白
    private func installPage(at index: Int, in cell: UICollectionViewCell) {
        guard pageViews.indices.contains(index) else { return }
        let page = pageViews[index]

        // 换页内容：清掉 cell 旧子视图再挂上当前 page
        if page.superview !== cell.contentView {
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.contentView.addSubview(page)
        }

        // 优先用 cell 已有尺寸；否则退回自身 bounds，避免首帧空白
        let targetBounds = cell.contentView.bounds
        if targetBounds.width > 0, targetBounds.height > 0 {
            page.frame = targetBounds
        } else if bounds.width > 0, bounds.height > 0 {
            page.frame = CGRect(origin: .zero, size: bounds.size)
        }

        page.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        page.setNeedsLayout()
        page.layoutIfNeeded()
    }

    // MARK: - 滚动回调

    /// 手指开始拖动：记录起点 offset，并通知 `willBeginDragging`
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户手势开始，允许后续 didScroll 发进度
        isProgrammaticScroll = false
        startOffsetX = scrollView.contentOffset.x
        delegate?.chatKeyboardPageViewWillBeginDragging(self)
    }

    /// 滑动中：按相对一页宽度计算 progress，回调 `didScrollFrom:to:progress:`（程序化滚动跳过）
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 程序化 setContentOffset / scrollToItem 不发进度，避免 Tab 联动抖动
        guard !isProgrammaticScroll else { return }

        // 一页宽度；至少为 1 防止除零
        let width = max(scrollView.bounds.width, 1)
        let currentX = scrollView.contentOffset.x
        let startIndex = Int(floor(startOffsetX / width))

        let endIndex: Int
        let progress: CGFloat

        if currentX > startOffsetX {
            // 向右滑：进度 = 已滑过宽度 / 页宽，目标页 = 起始页 + 1
            progress = (currentX - startOffsetX) / width
            endIndex = min(startIndex + 1, max(pageViews.count - 1, 0))
        } else if currentX == startOffsetX {
            // 未移动
            progress = 0
            endIndex = startIndex
        } else {
            // 向左滑：进度取绝对值方向，目标页 = 起始页 - 1
            progress = (startOffsetX - currentX) / width
            endIndex = max(startIndex - 1, 0)
        }

        delegate?.chatKeyboardPageView(self, didScrollFrom: startIndex, to: endIndex, progress: progress)
    }

    /// 减速结束：更新 `_currentIndex`，回调 `didEndDeceleratingFrom:to:`
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = max(scrollView.bounds.width, 1)
        // 拖动起点页 vs 减速后实际停住的页
        let startIndex = Int(floor(startOffsetX / width))
        let endIndex = Int(floor(scrollView.contentOffset.x / width))

        _currentIndex = endIndex
        isProgrammaticScroll = false
        // 通知外部（如表情 Tab）同步选中态
        delegate?.chatKeyboardPageView(self, didEndDeceleratingFrom: startIndex, to: endIndex)
    }

    /// 拖动结束：若不再减速，按 offset 四舍五入落页，并回调 `didEndDragging`
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 还会减速时交给 didEndDecelerating；否则在此处落页
        guard !decelerate else { return }

        let width = max(scrollView.bounds.width, 1)
        // 无惯性时 offset 可能停在两页之间，四舍五入到最近页
        _currentIndex = Int(round(scrollView.contentOffset.x / width))
        delegate?.chatKeyboardPageViewDidEndDragging(self)
    }

    /// 程序化动画滚动结束：清 `isProgrammaticScroll`，并同步 `_currentIndex`
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // 动画结束，恢复允许手势进度回调
        isProgrammaticScroll = false

        let width = max(scrollView.bounds.width, 1)
        // 与最终 offset 对齐当前页索引
        _currentIndex = Int(round(scrollView.contentOffset.x / width))
    }
}
