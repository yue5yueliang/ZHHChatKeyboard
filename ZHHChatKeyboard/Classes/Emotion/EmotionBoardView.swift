//
//  EmotionBoardView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 表情面板事件（默认空实现，按需覆写）。
///
/// 宿主实现选中、添加、删除、发送等行为；未用到的方法可忽略。
public protocol EmotionBoardViewDelegate: AnyObject {
    /// 选中某个表情；请根据 `group.tapAction` 决定写入输入框还是直接发送
    func emotionView(_ view: EmotionBoardView, didSelect emotion: Emotion, at index: Int, in group: EmotionGroup)
    /// 点击自定义组首格「添加」
    func emotionViewDidSelectAddButton(_ view: EmotionBoardView, in group: EmotionGroup)
    /// 点击浮层删除按钮（应删输入框中表情 / 退格）
    func emotionViewDidSelectDeleteButton(_ view: EmotionBoardView)
    /// 点击浮层发送按钮（通常取输入框纯文本发送并清空）
    func emotionViewDidSelectSendButton(_ view: EmotionBoardView)
}

public extension EmotionBoardViewDelegate {
    func emotionView(_ view: EmotionBoardView, didSelect emotion: Emotion, at index: Int, in group: EmotionGroup) {}
    func emotionViewDidSelectAddButton(_ view: EmotionBoardView, in group: EmotionGroup) {}
    func emotionViewDidSelectDeleteButton(_ view: EmotionBoardView) {}
    func emotionViewDidSelectSendButton(_ view: EmotionBoardView) {}
}

/// 表情面板（库默认实现）。
///
/// 结构：顶部组 Tab → `ChatKeyboardPageView` 横向分页（一组一页竖向网格）→ 右下删/发浮层（仅「写入输入框」组显示）。
/// 数据：`update(groups:)` 或 `dataSource`；异步出图走 `imageLoader`。
/// 高度：对外用 `boardHeight`（网格 + Tab）交给 `KeyboardManagerDataSource`。
open class EmotionBoardView: UIView {

    // MARK: - 常量

    // 右下删/发按钮尺寸与 Tab cell 复用 id
    static let buttonWidth: CGFloat = 52
    static let buttonHeight: CGFloat = 41
    static let groupCellId = "EmotionGroupTabCell"

    /// 顶部表情组 Tab 条高度
    public static let tabBarHeight: CGFloat = 44
    /// 表情网格区高度（不含顶部 Tab）
    public static let contentHeight: CGFloat = 318
    /// 表情整板高度 = 网格 + 顶部 Tab（供 `keyboardManagerEmotionBoardHeight` 使用）
    public static var boardHeight: CGFloat { contentHeight + tabBarHeight }

    // 布局计算用 Tab 高度（与 `tabBarHeight` 一致）
    static var tabHeight: CGFloat { tabBarHeight }

    // MARK: - 公开属性

    /// 表情组数据源；也可用 `update(groups:)` 注入数组
    public weak var dataSource: EmotionDataSource? {
        didSet { reloadData() }
    }

    /// 异步出图
    public weak var imageLoader: EmotionImageLoading?

    /// 选中表情 / 删发 / 添加回调
    public weak var delegate: EmotionBoardViewDelegate?

    /// 图文互转 helper；与 `KeyboardManager.emotionHelper` 应为同一实例
    public var emotionHelper = EmotionHelper()

    /// 强持有数组型数据源（`dataSource` 为 weak，避免 `StaticEmotionDataSource` 被释放）
    private var retainedDataSource: EmotionDataSource?

    /// 内容边距（左右最多 10；底部需给删/发留空；顶部 Tab 由 pageContentView.frame 避开）
    public var paddingInPage: UIEdgeInsets = UIEdgeInsets(top: 18, left: 10, bottom: 52, right: 10)
    /// 自定义贴纸 / GIF 页边距（左右最多 10；无删/发按钮，底部只需少量留白；安全区另加）
    public var stickerPaddingInPage: UIEdgeInsets = UIEdgeInsets(top: 12, left: 10, bottom: 8, right: 10)
    /// 默认小表情绘制尺寸（组为 `.emoji` 时；实际 cell 边长仍按列数均分）
    public var emotionSize: CGSize = CGSize(width: 34, height: 34)
    /// 表情 / 贴纸网格的 cell 间距（行列共用）
    public var cellSpacing: CGFloat = 8
    /// 小表情列数分界宽度：≤ 此值 7 列，更宽 8 列；cell 边长再按屏宽均分
    public var emojiColumnsBreakpoint: CGFloat = 375
    /// 自定义贴纸 / GIF 固定列数
    public var stickerColumns: Int = 5
    /// 贴纸 cell 底部名称行高（仅 `showsItemTitles == true` 时生效）
    public var stickerTitleHeight: CGFloat = 22

    // MARK: - 外观可配置项

    /// 面板背景色（表情网格区域）
    public var boardBackgroundColor: UIColor = ChatKeyboardColor.boardBackground {
        didSet { backgroundColor = boardBackgroundColor }
    }
    /// 顶部表情组 Tab 条背景色（默认与输入条同色，连成一块）
    public var tabBarBackgroundColor: UIColor = ChatKeyboardColor.barBackground {
        didSet { groupTabView.backgroundColor = tabBarBackgroundColor }
    }
    /// Tab 底部分割线颜色
    public var tabBarSeparatorColor: UIColor = ChatKeyboardColor.barSeparator {
        didSet { tabBottomLineView.backgroundColor = tabBarSeparatorColor }
    }
    /// 表情组 Tab 选中背景色
    public var tabSelectedBackgroundColor: UIColor = ChatKeyboardColor.tabSelectedFill {
        didSet { groupTabView.reloadData() }
    }

    /// 删除按钮图标；默认系统 `delete.backward`，可换成自有图
    public var deleteButtonImage: UIImage? = EmotionBoardView.makeDefaultDeleteButtonImage() {
        didSet { applyDeleteButtonStyle() }
    }
    /// 删除按钮图标颜色（系统符号时生效）
    public var deleteButtonTintColor: UIColor = ChatKeyboardColor.secondaryText {
        didSet { applyDeleteButtonStyle() }
    }
    /// 删除按钮背景色，默认输入框填充色
    public var deleteButtonBackgroundColor: UIColor? = ChatKeyboardColor.inputFill {
        didSet { applyDeleteButtonStyle() }
    }
    /// 删除按钮按下时背景色
    public var deleteButtonHighlightBackgroundColor: UIColor = ChatKeyboardColor.deleteButtonHighlight {
        didSet { applyDeleteButtonStyle() }
    }
    /// 删除按钮圆角，默认 4
    public var deleteButtonCornerRadius: CGFloat = 4 {
        didSet { applyDeleteButtonStyle() }
    }
    /// 删除按钮相对发送按钮的 (x,y) 偏移
    public var deleteButtonOffset: CGPoint = .zero

    /// 发送按钮文案，默认「发送」
    public var sendButtonTitle: String = "发送" {
        didSet { applySendButtonStyle() }
    }
    /// 发送按钮标题样式；非空时优先于默认白字 17pt
    public var sendButtonTitleAttributes: [NSAttributedString.Key: Any]? {
        didSet { applySendButtonStyle() }
    }
    /// 发送按钮背景色，默认发送绿
    public var sendButtonBackgroundColor: UIColor = ChatKeyboardColor.sendButton {
        didSet { applySendButtonStyle() }
    }
    /// 发送按钮按下时背景色
    public var sendButtonHighlightBackgroundColor: UIColor = ChatKeyboardColor.sendButtonHighlight {
        didSet { applySendButtonStyle() }
    }
    /// 发送按钮圆角，默认 4
    public var sendButtonCornerRadius: CGFloat = 4 {
        didSet { applySendButtonStyle() }
    }
    /// 发送按钮相对面板右下角的外边距（仅 right/bottom 有效）
    public var sendButtonMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 18)

    // MARK: - 子视图

    /// 横向分页容器（一组一页，可左右滑动切组）
    public private(set) lazy var pageContentView: ChatKeyboardPageView = {
        let view = ChatKeyboardPageView()
        view.delegate = self
        return view
    }()

    /// 兼容旧 API：指向分页底层 CollectionView
    public var collectionView: UICollectionView { pageContentView.collectionView }

    /// 表情组 Tab
    public private(set) lazy var groupTabView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        let view = TouchCancelCollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = ChatKeyboardColor.barBackground
        view.showsHorizontalScrollIndicator = false
        view.delaysContentTouches = false
        view.dataSource = self
        view.delegate = self
        view.register(EmotionGroupTabCell.self, forCellWithReuseIdentifier: Self.groupCellId)
        return view
    }()

    /// Tab 底部分割线（无 Tab 时画在面板顶，替代 ChatKeyboardView 顶线）
    lazy var tabBottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = ChatKeyboardColor.barSeparator
        return view
    }()

    /// 删/发按钮容器（挂在「写入输入框」那一组的 page 上，随横滑翻页带走；自定义 GIF 组不显示）
    public private(set) lazy var actionButtonsView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.addSubview(deleteButton)
        view.addSubview(sendButton)
        return view
    }()

    /// 发送按钮（样式由 `sendButton*` 系列属性 + `UIButton.Configuration` 驱动，点击走 `handleSend` → delegate）
    public private(set) lazy var sendButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()

    /// 删除按钮（样式由 `deleteButton*` 系列属性 + `UIButton.Configuration` 驱动，点击走 `handleDelete` → delegate）
    public private(set) lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        return button
    }()

    // MARK: - 内部状态

    var groups: [EmotionGroup] = []
    /// 当前选中的表情组下标（与 Tab、`pageContentView.currentIndex` 对齐）
    var selectedGroupIndex: Int = 0
    /// 每组对应的单页网格 View，顺序与 `groups` 一致
    var groupPageViews: [EmotionGroupPageView] = []
    /// `imageLoader` 异步拉取成功后的内存缓存（key = `emotion.identifier`）
    var cachedImages: [String: UIImage] = [:]
    /// 正在请求中的表情 id，避免同一张图并发重复加载
    var loadingImageIdentifiers: Set<String> = []
    /// 加载失败过的表情 id，本会话内不再重试
    var failedImageIdentifiers: Set<String> = []
    /// 承载删/发按钮的 page 下标（通常是默认小表情组）
    var actionButtonsPageIndex: Int?

    /// Tab 区高度约束（无 Tab 时置 0）
    var tabHeightConstraint: NSLayoutConstraint!
    /// Tab 底部分割线高度
    var tabLineHeightConstraint: NSLayoutConstraint!

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = boardBackgroundColor
        groupTabView.backgroundColor = tabBarBackgroundColor

        // 自上而下：Tab → 分割线 → 分页网格（Auto Layout）
        pageContentView.translatesAutoresizingMaskIntoConstraints = false
        groupTabView.translatesAutoresizingMaskIntoConstraints = false
        tabBottomLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pageContentView)
        addSubview(groupTabView)
        addSubview(tabBottomLineView)

        // 固定高度用 999：面板由外层 frame 动画时高度会短暂 < Tab+分割线，避免与 autoresizing 打架
        tabHeightConstraint = groupTabView.heightAnchor.constraint(equalToConstant: Self.tabHeight)
        tabHeightConstraint.priority = UILayoutPriority(999)
        tabLineHeightConstraint = tabBottomLineView.heightAnchor.constraint(equalToConstant: ChatKeyboardCommon.hairlineHeight)
        tabLineHeightConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            groupTabView.topAnchor.constraint(equalTo: topAnchor),
            groupTabView.leadingAnchor.constraint(equalTo: leadingAnchor),
            groupTabView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabHeightConstraint,

            tabBottomLineView.topAnchor.constraint(equalTo: groupTabView.bottomAnchor),
            tabBottomLineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBottomLineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabLineHeightConstraint,

            pageContentView.topAnchor.constraint(equalTo: tabBottomLineView.bottomAnchor),
            pageContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageContentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyDeleteButtonStyle()
        applySendButtonStyle()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 公开 API

    /// 用表情组列表更新面板（内部用 `StaticEmotionDataSource` 强持有）
    /// - Parameter groups: 业务表情组
    public func update(groups: [EmotionGroup]) {
        let source = StaticEmotionDataSource(groups: groups)

        // 强持有 + 赋给 weak dataSource，触发 didSet → reloadData
        retainedDataSource = source
        dataSource = source
        emotionHelper.configure(groups: groups)
        applyStyleForSelectedGroup()
    }

    /// 重新拉取 dataSource 并刷新 Tab、分页与各组网格
    public func reloadData() {
        if let dataSource {
            let count = max(0, dataSource.numberOfGroups(in: self))
            groups = (0..<count).map { dataSource.emotionBoardView(self, groupAt: $0) }
        } else {
            groups = []
        }

        // 组数变少时校正选中下标
        if selectedGroupIndex >= groups.count {
            selectedGroupIndex = max(0, groups.count - 1)
        }

        groupTabView.isHidden = groups.count <= 1
        tabHeightConstraint?.constant = groupTabView.isHidden ? 0 : Self.tabHeight
        applyStyleForSelectedGroup()
        rebuildPageViews()
        groupTabView.reloadData()
        setNeedsLayout()
    }

    // MARK: - 布局

    /// 按当前选中组的 style 同步 `emotionSize`（各页 configure 时仍用组内尺寸）
    func applyStyleForSelectedGroup() {
        guard groups.indices.contains(selectedGroupIndex) else { return }
        emotionSize = groups[selectedGroupIndex].style.emotionSize
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        // Tab 高度在 reloadData 已同步；此处确保与 isHidden 一致（避免约束未就绪）
        let tabH: CGFloat = groupTabView.isHidden ? 0 : Self.tabHeight
        if tabHeightConstraint.constant != tabH {
            tabHeightConstraint.constant = tabH
        }
        tabBottomLineView.isHidden = false

        // 先让分页 cell / page 拿到真实尺寸，再配网格与删发按钮，避免空页或全透明
        pageContentView.layoutIfNeeded()

        // 尺寸变化后刷新各页网格布局，并把删/发钉在「写入输入框」那一页上
        for (index, page) in groupPageViews.enumerated() where groups.indices.contains(index) {
            configurePageView(page, at: index)
        }
        layoutActionButtonsIfNeeded()

        // Tab / 分割线盖在分页之上，避免横滑时被表情盖住
        bringSubviewToFront(groupTabView)
        bringSubviewToFront(tabBottomLineView)

        // 删/发按钮区域对应的 cell 降透明，避免与按钮叠层抢点
        adjustEmotionsAlpha()
    }
}

