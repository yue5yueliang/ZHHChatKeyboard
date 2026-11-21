//
//  EmotionGroupPageView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 分组页（一页一组竖向表情网格）

/// 单组表情承载页：竖向 `UICollectionView` 网格，可选首格「添加」。
final class EmotionGroupPageView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // 单格表情 / 添加占位 cell 复用 id
    private static let emotionCellId = "EmotionCell"

    // MARK: - 网格状态

    /// 当前页的列数、间距、cell 尺寸等（与 FlowLayout 同步）
    private(set) var gridLayout = EmotionGridLayout(
        contentInset: .zero,
        itemSize: CGSize(width: 34, height: 34),
        columns: 1,
        horizontalGap: 0,
        lineSpacing: 0,
        emotionSize: CGSize(width: 34, height: 34),
        showsTitle: false
    )

    /// 本组表情列表（与 dataSource 一一对应）
    private var emotions: [Emotion] = []
    /// 是否在网格首格显示「添加」按钮
    private var showsAddButton = false

    /// 同步取图：模型内建图 / 面板缓存
    private var imageProvider: ((Emotion) -> UIImage?)?
    /// 缺图时回调面板异步加载
    private var requestImage: ((Emotion, IndexPath) -> Void)?
    /// 点选表情（参数为 emotions 下标）
    private var didSelect: ((Int) -> Void)?
    /// 点选「添加」按钮
    private var didSelectAdd: (() -> Void)?
    /// 竖向滚动时通知面板刷新删/发遮罩
    private var onScroll: (() -> Void)?
    /// cell 即将显示时通知面板刷新遮罩（下一 runloop）
    private var onDisplay: (() -> Void)?
    /// 上次 layout 时的 bounds，用于判断是否需要 invalidate
    private var lastLayoutBounds: CGSize = .zero

    // MARK: - 子视图

    /// 本组竖向表情网格
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = TouchCancelCollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = true
        view.delaysContentTouches = false
        view.dataSource = self
        view.delegate = self
        view.register(EmotionCollectionCell.self, forCellWithReuseIdentifier: Self.emotionCellId)
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    // MARK: - Item 映射

    /// 网格 item 总数（含可选的首格「添加」）
    private var itemCount: Int {
        emotions.count + (showsAddButton ? 1 : 0)
    }

    /// 将 collection item 下标映射为 `emotions` 数组下标；item 0 为添加格时返回 nil
    private func emotionIndex(forItem item: Int) -> Int? {
        if showsAddButton {
            guard item > 0 else { return nil }
            return item - 1
        }
        return item
    }

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 布局

    /// 尺寸变化时 invalidate FlowLayout（网格本身由约束铺满）
    override func layoutSubviews() {
        super.layoutSubviews()

        let size = bounds.size
        guard size.width > 1, size.height > 1, size != lastLayoutBounds else { return }
        lastLayoutBounds = size
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - 数据注入

    /// 更新本组表情数据、网格布局与各回调闭包，并 reload 集合视图
    func configure(
        emotions: [Emotion],
        layout: EmotionGridLayout,
        showsAddButton: Bool,
        imageProvider: @escaping (Emotion) -> UIImage?,
        requestImage: @escaping (Emotion, IndexPath) -> Void,
        didSelect: @escaping (Int) -> Void,
        didSelectAdd: @escaping () -> Void,
        onScroll: @escaping () -> Void,
        onDisplay: @escaping () -> Void
    ) {
        // 写入数据与回调
        self.emotions = emotions
        self.gridLayout = layout
        self.showsAddButton = showsAddButton
        self.imageProvider = imageProvider
        self.requestImage = requestImage
        self.didSelect = didSelect
        self.didSelectAdd = didSelectAdd
        self.onScroll = onScroll
        self.onDisplay = onDisplay

        // 尺寸已就绪时先走完布局，避免 reload 用旧 bounds
        if bounds.width > 0, collectionView.bounds.size != bounds.size {
            layoutIfNeeded()
        }

        // 记录 reload 前滚动位置，便于顶部对齐校正
        let previousInset = collectionView.contentInset
        let previousOffset = collectionView.contentOffset
        // 原本就在顶部附近时，reload 后仍应对齐 -inset，避免贴边
        let wasNearTop = previousOffset.y <= -previousInset.top + 1

        // 同步 inset 与 FlowLayout 尺寸
        collectionView.contentInset = layout.contentInset
        collectionView.scrollIndicatorInsets = layout.contentInset
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.itemSize = layout.itemSize
            flow.minimumLineSpacing = layout.lineSpacing
            flow.minimumInteritemSpacing = layout.horizontalGap
            flow.invalidateLayout()
        }
        collectionView.reloadData()

        // 顶部附近：垂直 offset 拉回 -inset.top，水平不动
        let inset = layout.contentInset
        if inset.top > 0, wasNearTop || (previousOffset.y > -inset.top && previousOffset.y < 1) {
            collectionView.setContentOffset(CGPoint(x: previousOffset.x, y: -inset.top), animated: false)
        }
    }

    // MARK: - UICollectionViewDataSource / Delegate

    /// 本组网格 item 数（含添加格）
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        itemCount
    }

    /// 配置表情格或首格「添加」；无图时触发 `requestImage`
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.emotionCellId, for: indexPath) as! EmotionCollectionCell

        // 首格「添加」占位
        if showsAddButton, indexPath.item == 0 {
            cell.configureAsAddButton(emotionSize: gridLayout.emotionSize)
            return cell
        }

        // 普通表情格：取图，缺图则异步请求
        guard let emotionIndex = emotionIndex(forItem: indexPath.item), emotions.indices.contains(emotionIndex) else {
            return cell
        }
        let emotion = emotions[emotionIndex]
        cell.configure(
            image: imageProvider?(emotion),
            title: gridLayout.showsTitle ? emotion.resolvedAccessibilityLabel : nil,
            accessibilityLabel: emotion.resolvedAccessibilityLabel,
            emotionSize: gridLayout.emotionSize
        )
        requestImage?(emotion, indexPath)
        return cell
    }

    /// cell 即将显示时通知外层刷新删/发遮罩
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        onDisplay?()
    }

    /// 选中表情或「添加」；alpha 过低或被遮罩禁用时忽略
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let cell = collectionView.cellForItem(at: indexPath), cell.alpha > 0.05, cell.isUserInteractionEnabled else { return }

        if showsAddButton, indexPath.item == 0 {
            didSelectAdd?()
            return
        }
        guard let emotionIndex = emotionIndex(forItem: indexPath.item) else { return }
        didSelect?(emotionIndex)
    }

    /// item 尺寸取自 FlowLayout（与 `gridLayout` 同步）
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return layout.itemSize
        }
        return gridLayout.itemSize
    }

    // MARK: - 滚动

    /// 纵向滚动时回调外层更新删/发遮罩
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?()
    }
}