//
//  ExtendBoardView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - Delegate

/// 扩展面板点击回调（默认空实现）
public protocol ExtendBoardViewDelegate: AnyObject {
    /// 点击某个「更多」入口
    /// - Parameters:
    ///   - item: 入口模型
    ///   - index: 在 `items` 中的下标
    func didSelectExtendBoardItem(_ item: ExtendBoardItem, at index: Int)
}

public extension ExtendBoardViewDelegate {
    /// 默认空实现
    func didSelectExtendBoardItem(_ item: ExtendBoardItem, at index: Int) {}
}

/// 「+」扩展面板（ExtendBoard 模块；库默认实现）。
///
/// 职责：横向分页展示「相册 / 拍摄」等入口网格，底部 `UIPageControl` 同步页码。
/// 用法：
/// - 每页固定列数×2 行；高度用 `contentHeight`（不含底部安全区），`KeyboardManager` 展示时再加安全区
/// - 设置 `items` 或 `update(items:)` 刷新；点击走 `ExtendBoardViewDelegate`
open class ExtendBoardView: UIView {

    // MARK: - 常量

    /// Cell 复用标识
    private static let cellId = "ExtendBoardItemCell"
    /// 底部分页指示器高度
    private let pageControlHeight: CGFloat = 28
    /// 单行内容高度：白底卡片 + 标题（宽度由列均分，不写死）
    private let itemContentHeight: CGFloat = 83
    /// 每页行数（固定 2 行）
    private let perColumnCount = 2
    /// 行间距（固定）
    private let rowSpacing: CGFloat = 18

    /// 扩展面板内容区高度（不含底部安全区；Manager 展示时再加 `safeAreaInsets.bottom`）
    /// 上边距 12 + 两行内容高(83×2) + 行距 18 + 下边距 12 + PageControl 28
    public static let contentHeight: CGFloat = 236

    // MARK: - 数据与回调

    /// 入口列表；赋值后自动刷新分页
    public var items: [ExtendBoardItem] = [] {
        didSet { reloadData() }
    }

    /// 点击回调
    public weak var delegate: ExtendBoardViewDelegate?

    // MARK: - 外观

    /// 面板背景色
    public var boardBackgroundColor: UIColor = ChatKeyboardColor.boardBackground {
        didSet { backgroundColor = boardBackgroundColor }
    }
    /// 入口标题色
    public var itemTitleColor: UIColor = ChatKeyboardColor.secondaryText {
        didSet { collectionView.reloadData() }
    }
    /// 入口卡片底色
    public var itemCardBackgroundColor: UIColor = ChatKeyboardColor.inputFill {
        didSet { collectionView.reloadData() }
    }
    /// 入口卡片按下底色
    public var itemCardHighlightColor: UIColor = ChatKeyboardColor.itemCardHighlight {
        didSet { collectionView.reloadData() }
    }
    /// 角标背景色
    public var itemBadgeBackgroundColor: UIColor = ChatKeyboardColor.badge {
        didSet { collectionView.reloadData() }
    }
    /// 分页当前指示点颜色
    public var currentPageIndicatorTintColor: UIColor = ChatKeyboardColor.pageIndicatorCurrent {
        didSet { pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor }
    }
    /// 分页未选中指示点颜色
    public var pageIndicatorTintColor: UIColor = ChatKeyboardColor.pageIndicator {
        didSet { pageControl.pageIndicatorTintColor = pageIndicatorTintColor }
    }

    // MARK: - 子视图

    /// 分页网格（底层 `TouchCancelCollectionView` + 自定义 `ExtendBoardLayout`）
    public private(set) lazy var collectionView: UICollectionView = {
        let layout = ExtendBoardLayout()
        layout.itemContentHeight = itemContentHeight
        layout.perColumnCount = perColumnCount
        layout.rowSpacing = rowSpacing

        let view = TouchCancelCollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        view.dataSource = self
        view.delegate = self

        // 仅 iconButton 可点，不走 cell 选中
        view.allowsSelection = false
        // 立刻把触摸交给 button，轻点也能马上看到高亮（默认 true 会拖到认定非滚动才下发）
        view.delaysContentTouches = false

        registerCells(in: view)
        return view
    }()

    /// 底部分页指示器（页数 ≤1 时隐藏）
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = ChatKeyboardColor.pageIndicatorCurrent
        control.pageIndicatorTintColor = ChatKeyboardColor.pageIndicator
        control.addTarget(self, action: #selector(pageChanged), for: .valueChanged)
        return control
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = boardBackgroundColor

        // 网格铺满 PageControl 之上；PageControl 贴安全区底
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        addSubview(pageControl)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor),

            pageControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: pageControlHeight),
            pageControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 布局

    /// 同步 Layout 指标与页码（子视图位置由 Auto Layout 负责）
    open override func layoutSubviews() {
        super.layoutSubviews()

        updateLayoutMetrics()
        collectionView.collectionViewLayout.invalidateLayout()
        updatePageControl()
    }

    /// 安全区变化时重排（横竖屏、Home 条）
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    // MARK: - 公开 API

    /// 用入口列表更新面板（与表情面板 `update(groups:)` 同形）
    /// - Parameter items: 业务入口
    public func update(items: [ExtendBoardItem]) {
        self.items = items
    }

    /// 根据数据源刷新网格与分页指示器
    public func reloadData() {
        updateLayoutMetrics()
        collectionView.reloadData()
        updatePageControl()
        setNeedsLayout()
    }

    /// 刷新单个入口（会走 `items` didSet 全量刷新）
    public func reloadItem(at index: Int, icon: UIImage?, title: String, badgeText: String? = nil) {
        guard items.indices.contains(index) else { return }

        var next = items
        next[index] = ExtendBoardItem(icon: icon, title: title, badgeText: badgeText)
        items = next
    }

    /// 子类可更换 Cell 注册
    open func registerCells(in collectionView: UICollectionView) {
        collectionView.register(ExtendBoardItemCell.self, forCellWithReuseIdentifier: Self.cellId)
    }

    /// 子类可更换 Cell 出队
    open func dequeueItemCell(in collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellId, for: indexPath)
    }

    /// 子类可自定义 Cell 绑定
    open func configureItemCell(_ cell: UICollectionViewCell, item: ExtendBoardItem, at index: Int) {
        guard let cell = cell as? ExtendBoardItemCell else { return }

        // 外观跟随面板公开属性
        cell.iconButton.normalBackgroundColor = itemCardBackgroundColor
        cell.iconButton.highlightBackgroundColor = itemCardHighlightColor
        cell.titleLabel.textColor = itemTitleColor
        cell.badgeLabel.backgroundColor = itemBadgeBackgroundColor

        cell.configure(item: item)

        // 点击白底卡片 → delegate
        cell.onIconTap = { [weak self] in
            guard let self, self.items.indices.contains(index) else { return }
            self.delegate?.didSelectExtendBoardItem(self.items[index], at: index)
        }
    }

    // MARK: - 私有

    /// 把入口数量、列数等写入自定义 Layout
    private func updateLayoutMetrics() {
        guard let layout = collectionView.collectionViewLayout as? ExtendBoardLayout else { return }

        layout.itemCount = items.count
        // iPad 更宽：一页 10 列；手机 4 列
        layout.perRow = UIDevice.current.userInterfaceIdiom == .pad ? 10 : 4
        layout.itemContentHeight = itemContentHeight
        layout.perColumnCount = perColumnCount
        layout.rowSpacing = rowSpacing
    }

    /// 按每页容量计算 `UIPageControl` 页数与显隐
    private func updatePageControl() {
        let perRow = UIDevice.current.userInterfaceIdiom == .pad ? 10 : 4
        let perPage = max(1, perRow * perColumnCount)
        let pageCount = items.isEmpty ? 0 : Int(ceil(Double(items.count) / Double(perPage)))

        pageControl.numberOfPages = pageCount
        pageControl.isHidden = pageCount <= 1

        // 数据变少时当前页不能越界
        if pageControl.currentPage >= pageCount {
            pageControl.currentPage = max(0, pageCount - 1)
        }
    }

    /// 由 Collection 横向偏移同步 PageControl 当前页
    private func syncPageControlWithOffset() {
        let pageWidth = max(bounds.width, 1)
        pageControl.currentPage = Int(round(collectionView.contentOffset.x / pageWidth))
    }

    /// 用户点 PageControl 时滚动到对应页
    @objc private func pageChanged() {
        let pageWidth = max(bounds.width, 1)
        collectionView.setContentOffset(CGPoint(x: CGFloat(pageControl.currentPage) * pageWidth, y: 0), animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ExtendBoardView: UICollectionViewDataSource, UICollectionViewDelegate {

    /// item 数量等于 `items.count`
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    /// 出队并绑定入口数据
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueItemCell(in: collectionView, at: indexPath)
        let item = items[indexPath.item]
        configureItemCell(cell, item: item, at: indexPath.item)
        return cell
    }

    // MARK: - 滚动回调

    /// 用户手势分页结束，同步指示器
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncPageControlWithOffset()
    }

    /// 程序化 / PageControl 触发的动画滚动结束，同步指示器
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncPageControlWithOffset()
    }
}