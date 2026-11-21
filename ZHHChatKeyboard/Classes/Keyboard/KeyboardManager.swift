//
//  KeyboardManager.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 输入状态

/// 输入状态：无面板 / 系统键盘 / 表情板 / 扩展板
public enum KeyboardInputState: Int {
    /// 默认：无键盘也无面板
    case normal = 0
    /// 系统软键盘
    case text
    /// 表情面板
    case emotion
    /// 扩展面板
    case extend
}

// MARK: - 高度变化原因

/// 整个输入区（bar + 面板/键盘，不含底部安全区）高度变化原因
public enum WholeInputViewHeightChangeReason: Int {
    /// 输入条被 add 到 VC
    case willAddToSuperview = 0
    /// 文本换行等导致高度变化
    case textDidChange
    /// 点发送清空导致变矮（动画策略可与 textDidChange 区分）
    case textDidSend
    /// 显示了软键盘或面板
    case boardDidShow
    /// 隐藏了软键盘或面板
    case boardDidHide
}

// MARK: - DataSource

/// 提供表情/扩展面板 View、高度，以及可注入的表情组 / 更多项（一套 DataSource 喂数据）
public protocol KeyboardManagerDataSource: AnyObject {
    /// 表情面板 View；返回 `EmotionBoardView` 时可配合 `keyboardManagerEmotionGroups` 自动灌数据
    func keyboardManagerEmotionBoardView(_ manager: KeyboardManager) -> UIView?
    /// 扩展面板 View；返回 `ExtendBoardView` 时可配合 `keyboardManagerExtendBoardItems` 自动灌数据
    func keyboardManagerExtendBoardView(_ manager: KeyboardManager) -> UIView?

    /// 表情面板高度（含顶部 Tab）；默认 `EmotionBoardView.boardHeight`
    func keyboardManagerEmotionBoardHeight(_ manager: KeyboardManager) -> CGFloat
    /// 扩展面板内容高度（不含底部安全区）；默认 `ExtendBoardView.contentHeight`，展示时由 Manager 加上安全区
    func keyboardManagerExtendBoardHeight(_ manager: KeyboardManager) -> CGFloat

    /// 表情组列表；非空且面板为 `EmotionBoardView` 时自动 `update(groups:)` 并配置本会话 `emotionHelper`
    func keyboardManagerEmotionGroups(_ manager: KeyboardManager) -> [EmotionGroup]
    /// 「更多」入口列表；非空且面板为 `ExtendBoardView` 时自动 `update(items:)`
    func keyboardManagerExtendBoardItems(_ manager: KeyboardManager) -> [ExtendBoardItem]
}

public extension KeyboardManagerDataSource {
    /// 默认不提供表情面板
    func keyboardManagerEmotionBoardView(_ manager: KeyboardManager) -> UIView? { nil }
    /// 默认不提供扩展面板
    func keyboardManagerExtendBoardView(_ manager: KeyboardManager) -> UIView? { nil }

    /// 默认表情面板高度（网格 318 + 顶部 Tab 44）
    func keyboardManagerEmotionBoardHeight(_ manager: KeyboardManager) -> CGFloat { EmotionBoardView.boardHeight }
    /// 默认扩展面板内容高度（不含底部安全区）
    func keyboardManagerExtendBoardHeight(_ manager: KeyboardManager) -> CGFloat { ExtendBoardView.contentHeight }

    /// 默认无表情组（不自动注入）
    func keyboardManagerEmotionGroups(_ manager: KeyboardManager) -> [EmotionGroup] { [] }
    /// 默认无「更多」项（不自动注入）
    func keyboardManagerExtendBoardItems(_ manager: KeyboardManager) -> [ExtendBoardItem] { [] }
}

// MARK: - Delegate

/// 整体输入区高度变化回调
public protocol KeyboardManagerDelegate: AnyObject {
    /// 回调已在动画 block 内，外部不要再包一层动画（除非特殊需求）；height 不含底部安全区
    func keyboardManager(_ manager: KeyboardManager, wholeInputViewHeightDidChange height: CGFloat, reason: WholeInputViewHeightChangeReason)
}

public extension KeyboardManagerDelegate {
    /// 默认空实现
    func keyboardManager(_ manager: KeyboardManager, wholeInputViewHeightDidChange height: CGFloat, reason: WholeInputViewHeightChangeReason) {}
}

// MARK: - KeyboardManager

/// 核心键盘管理器。
///
/// 职责：
/// - 将输入条挂到 `ChatKeyboardView`，再贴到宿主 VC
/// - 状态机：`normal` / `text`（系统键盘）/ `emotion` / `extend`，避免面板与键盘抢动画
/// - 高度回调 `wholeInputViewHeightDidChange`（不含底部安全区），供列表 `contentInset` 使用
/// - `belowViewController == true` 时平时藏在屏外（朋友圈 / 点按钮再评论）
///
/// 用法：`addBottomChatInputBarView` → `bindTextView` → 实现 DataSource 提供面板与数据。
/// 会话边界：每个 Manager 自带 `emotionHelper`，多聊天页互不覆盖映射表；只读 `inputState` 查询当前态。
open class KeyboardManager: KeyboardBaseManager {

    // MARK: - 公开属性

    /// 本会话表情图文互转；与挂上的 `EmotionBoardView.emotionHelper` 共用同一实例
    public let emotionHelper = EmotionHelper()

    /// 当前输入状态（只读）；由状态机在切面板 / 系统键盘时更新
    public private(set) var inputState: KeyboardInputState = .normal

    /// 面板 DataSource（设值后会尝试把表情组 / 更多项灌进默认面板）
    public weak var dataSource: KeyboardManagerDataSource? {
        didSet { reloadPanelDataFromDataSource() }
    }
    /// 高度变化 Delegate
    public weak var delegate: KeyboardManagerDelegate?

    /// 侧滑返回时置 true，忽略 keyboard notification，避免 frame 被改乱
    public var viewControllerWillDisappear: Bool = false

    /// 整块聊天键盘区背景是否透明（镂空）
    public var chatKeyboardViewBackgroundClear: Bool = false {
        didSet { chatKeyboardView?.isBackgroundClear = chatKeyboardViewBackgroundClear }
    }

    /// 整块聊天键盘区实心背景色；nil 则跟输入条
    public var chatKeyboardViewBackgroundColor: UIColor? {
        didSet { chatKeyboardView?.solidBackgroundColor = chatKeyboardViewBackgroundColor }
    }

    // MARK: - 内部状态

    /// true：平时隐藏输入条（朋友圈 / 评论栏）；false：常驻底部（聊天）
    private var inputBarBelowViewController: Bool = false

    /// 绑定的输入框（系统键盘 / 焦点）
    private weak var inputTextView: UIResponder?
    /// 当前输入条（库默认条或业务自建 UIView）
    private var inputBarView: UIView?
    /// 整块聊天键盘区容器
    private var chatKeyboardView: ChatKeyboardView?

    /// 表情板（首次切表情时从 DataSource 取）
    private var emotionBoardView: UIView?
    /// 扩展板（首次切扩展时从 DataSource 取）
    private var extendBoardView: UIView?

    /// 底部安全区高度
    private var safeAreaInsetsBottom: CGFloat = 0
    /// 业务面板高度（表情 / 扩展）；系统键盘时为 0
    private var currentBoardHeight: CGFloat = 0
    /// 系统键盘顶边 Y（VC.view 坐标）；仅系统键盘弹出时有效，供换行重排贴键盘顶
    private var systemKeyboardMinY: CGFloat?

    // MARK: - 公开 API（输入条）

    /// 添加底部输入条；belowViewController=true 表示平时藏在屏幕外。
    /// 重复调用会先卸掉旧的 `ChatKeyboardView`（Demo 切换常驻 / 隐藏时可用）。
    public func addBottomChatInputBarView(_ inputBarView: UIView, belowViewController: Bool) {
        guard let hostView = resolvedHostView else { return }

        // 复位状态，卸掉旧容器
        hideAllBoardView()
        chatKeyboardView?.removeFromSuperview()
        chatKeyboardView = nil

        // 安全区：优先 hostView；为 0（尚未入窗等）时退到 keyWindow
        safeAreaInsetsBottom = hostView.safeAreaInsets.bottom
        if safeAreaInsetsBottom <= 0 {
            safeAreaInsetsBottom = ChatKeyboardCommon.keyWindowSafeAreaInsets.bottom
        }

        // 写入挂载模式与状态机初值
        self.inputBarView = inputBarView
        self.inputBarBelowViewController = belowViewController
        self.currentBoardHeight = 0
        self.inputState = .normal

        // 组装 ChatKeyboardView 并安装输入条
        let keyboardView = ChatKeyboardView(frame: .zero)
        keyboardView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        keyboardView.isBackgroundClear = chatKeyboardViewBackgroundClear
        keyboardView.solidBackgroundColor = chatKeyboardViewBackgroundColor
        keyboardView.installChatInputBarView(inputBarView)
        chatKeyboardView = keyboardView

        // 首次布局并挂到宿主 VC
        let barH = inputBarView.bounds.height
        let boardH: CGFloat = belowViewController ? 0 : safeAreaInsetsBottom
        layoutChatKeyboardView(barHeight: barH, boardHeight: boardH, placeOffScreen: belowViewController)
        hostView.addSubview(keyboardView)
        hostView.bringSubviewToFront(keyboardView)

        callBackWholeInputViewHeightDidChange(belowViewController ? 0 : barH, reason: .willAddToSuperview)
    }

    /// 绑定输入框；仅该 responder 为 firstResponder 时才处理键盘事件
    public func bindTextView(_ inputTextView: UIResponder) {
        self.inputTextView = inputTextView
    }

    /// 替换底部输入条（配置热更新时用），保留当前面板状态并重新布局
    public func replaceChatInputBarView(_ inputBarView: UIView) {
        // 无容器时走完整安装
        guard let keyboardView = chatKeyboardView else {
            addBottomChatInputBarView(inputBarView, belowViewController: inputBarBelowViewController)
            return
        }

        // 替换输入条
        self.inputBarView = inputBarView
        keyboardView.installChatInputBarView(inputBarView)

        // 按当前状态算布局参数
        let barH = max(inputBarView.bounds.height, ChatInputBarView.minHeight)
        let boardH = boardHeightForLayout()
        let offScreen = inputBarBelowViewController && inputState == .normal && currentBoardHeight == 0

        // 系统键盘态贴 keyboard 顶
        let keyboardDockY: CGFloat? = {
            guard inputState == .text, let keyboardY = systemKeyboardMinY else { return nil }
            return keyboardY - barH
        }()

        layoutChatKeyboardView(barHeight: barH, boardHeight: boardH, keyboardMinY: keyboardDockY, placeOffScreen: offScreen)
        callBackWholeInputViewHeightDidChange(callbackHeight(), reason: .willAddToSuperview)
    }

    /// 输入框高度变化后通知 Manager 回调整体高度
    public func inputTextViewHeightDidChange(becauseSendText: Bool) {
        guard let inputBarView else { return }

        // 按当前状态算布局参数
        let barH = inputBarView.bounds.height
        let boardH = boardHeightForLayout()
        let offScreen = inputBarBelowViewController && inputState == .normal && currentBoardHeight == 0

        // 系统键盘态必须继续贴键盘顶；不能落到屏幕底（键盘背后是镂空）
        let keyboardDockY: CGFloat? = {
            guard inputState == .text, let keyboardY = systemKeyboardMinY else { return nil }
            return keyboardY - barH
        }()

        layoutChatKeyboardView(barHeight: barH, boardHeight: boardH, keyboardMinY: keyboardDockY, placeOffScreen: offScreen)
        callBackWholeInputViewHeightDidChange(callbackHeight(), reason: becauseSendText ? .textDidSend : .textDidChange)
    }

    // MARK: - 公开 API（面板切换）

    /// 隐藏表情板、扩展板与软键盘
    public func hideAllBoardView() {
        if inputState != .normal {
            hideKeyboardAndSwitchToCurrentBoardView(allBoardHide: true)
        }
    }

    /// 切换到表情面板
    public func switchToEmotionBoard() {
        inputState = .emotion
        hideKeyboardAndSwitchToCurrentBoardView(allBoardHide: false)
    }

    /// 切换到扩展面板
    public func switchToExtendBoard() {
        inputState = .extend
        hideKeyboardAndSwitchToCurrentBoardView(allBoardHide: false)
    }

    /// 从 DataSource 刷新表情组 / 更多项（可在业务更新数据后主动调用）
    public func reloadPanelDataFromDataSource() {
        // 表情组：先配会话 helper，再灌进面板（面板与 helper 同一实例）
        let groups = dataSource?.keyboardManagerEmotionGroups(self) ?? []
        if !groups.isEmpty {
            emotionHelper.configure(groups: groups)
        }
        if let board = emotionBoardView as? EmotionBoardConfigurable {
            board.emotionHelper = emotionHelper
            if !groups.isEmpty {
                board.update(groups: groups)
            }
        }

        // 更多项
        let items = dataSource?.keyboardManagerExtendBoardItems(self) ?? []
        if let board = extendBoardView as? ExtendBoardConfigurable, !items.isEmpty {
            board.update(items: items)
        }
    }

    /// 局部刷新输入条外观（颜色 / 图标 / placeholder 等）；布局风格变更请仍用 `replaceChatInputBarView`
    /// - Parameter configuration: 新配置；仅 `ChatInputBarView` 生效
    public func updateChatInputBarAppearance(from configuration: ChatInputBarConfiguration) {
        (inputBarView as? ChatInputBarView)?.updateAppearance(from: configuration)
    }

    // MARK: - 键盘通知

    /// 系统键盘将显/隐：仅在 `text` 态、绑定输入框为 firstResponder 时联动整体 frame
    open override func onKeyboardWillShowOrHide(keyboardRect: CGRect, animationOptions: UIView.AnimationOptions, duration: Double, showKeyboard: Bool) {
        guard let inputTextView, inputTextView.isFirstResponder else { return }
        if viewControllerWillDisappear { return }
        guard let hostView = resolvedHostView, let barView = inputBarView, chatKeyboardView != nil else { return }

        // 系统键盘弹出时切 text 态
        if showKeyboard {
            inputState = .text
        }

        // 仅系统键盘态响应 will 通知；表情/扩展走自有动画
        guard inputState == .text else { return }

        // 按键盘 frame 动画整体位置
        let keyboardY = hostView.convert(keyboardRect, from: nil).origin.y
        UIView.animate(withDuration: duration, delay: 0, options: animationOptions, animations: { [weak self] in
            guard let self else { return }

            if showKeyboard {
                // 清业务面板，整体贴上键盘顶
                self.systemKeyboardMinY = keyboardY
                self.chatKeyboardView?.displayBoardView(nil)
                self.currentBoardHeight = 0
                self.layoutChatKeyboardView(barHeight: barView.bounds.height, boardHeight: 0, keyboardMinY: keyboardY - barView.bounds.height)
            } else {
                // 键盘收起 → normal；常驻模式垫安全区
                self.systemKeyboardMinY = nil
                self.inputState = .normal
                self.currentBoardHeight = 0
                let boardH = self.inputBarBelowViewController ? 0 : self.safeAreaInsetsBottom
                self.layoutChatKeyboardView(barHeight: barView.bounds.height, boardHeight: boardH, placeOffScreen: self.inputBarBelowViewController)
            }

            self.callBackWholeInputViewHeightDidChange(self.callbackHeight(), reason: showKeyboard ? .boardDidShow : .boardDidHide)
        })
    }

    // MARK: - 面板懒加载

    /// 首次需要扩展板时从 DataSource 取 View 并缓存
    @discardableResult
    private func ensureExtendBoardView() -> UIView? {
        if let extendBoardView { return extendBoardView }
        guard let view = dataSource?.keyboardManagerExtendBoardView(self) else { return nil }

        // 缓存并灌数据
        extendBoardView = view
        applyExtendBoardItemsIfNeeded(to: view)
        return view
    }

    /// 首次需要表情板时从 DataSource 取 View 并缓存
    @discardableResult
    private func ensureEmotionBoardView() -> UIView? {
        if let emotionBoardView { return emotionBoardView }
        guard let view = dataSource?.keyboardManagerEmotionBoardView(self) else { return nil }

        // 缓存并灌数据
        emotionBoardView = view
        applyEmotionGroupsIfNeeded(to: view)
        return view
    }

    /// 若面板遵循 `EmotionBoardConfigurable`：绑定本会话 helper，有数据则灌入
    private func applyEmotionGroupsIfNeeded(to view: UIView) {
        guard let board = view as? EmotionBoardConfigurable else { return }
        board.emotionHelper = emotionHelper
        let groups = dataSource?.keyboardManagerEmotionGroups(self) ?? []
        guard !groups.isEmpty else { return }
        emotionHelper.configure(groups: groups)
        board.update(groups: groups)
    }

    /// 若面板遵循 `ExtendBoardConfigurable` 且 DataSource 有数据则灌入
    private func applyExtendBoardItemsIfNeeded(to view: UIView) {
        guard let board = view as? ExtendBoardConfigurable else { return }
        let items = dataSource?.keyboardManagerExtendBoardItems(self) ?? []
        guard !items.isEmpty else { return }
        board.update(items: items)
    }

    // MARK: - 状态机：收起 / 切板

    /// 收键盘并切到当前业务面板，或 `allBoardHide` 时全收起
    private func hideKeyboardAndSwitchToCurrentBoardView(allBoardHide: Bool) {
        if allBoardHide && inputState == .text {
            inputState = .normal
        }

        // 先收系统键盘，清键盘锚点并懒加载面板
        inputTextView?.resignFirstResponder()
        systemKeyboardMinY = nil
        _ = ensureExtendBoardView()
        _ = ensureEmotionBoardView()

        guard let barView = inputBarView, let keyboardView = chatKeyboardView, let hostView = resolvedHostView else { return }
        let barH = barView.bounds.height
        let width = hostView.bounds.width
        let hostH = hostView.bounds.height

        // ── 分支 A：全部收起
        if allBoardHide {
            // 准备尺寸
            let endSlot = inputBarBelowViewController ? 0 : safeAreaInsetsBottom
            let endH = barH + endSlot

            // 动画：先保持 A=B+C/D，让 C/D 滑到 A 底边外，再把 A 收到 B+安全区
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self else { return }
                keyboardView.placeBoardViewBelowKeyboardViewForDismiss()
                keyboardView.layoutContent(barHeight: barH, boardHeight: endSlot, width: width, pinBoardViewInSlot: false)
                keyboardView.applyBackgroundColor()

                if self.inputBarBelowViewController {
                    keyboardView.frame = CGRect(x: 0, y: hostH, width: width, height: endH)
                } else {
                    keyboardView.frame = CGRect(x: 0, y: hostH - endH, width: width, height: endH)
                }
                self.currentBoardHeight = 0
                self.callBackWholeInputViewHeightDidChange(self.callbackHeight(), reason: .boardDidHide)
            }, completion: { [weak self] _ in
                keyboardView.displayBoardView(nil)
                self?.inputState = .normal
            })
            return
        }

        // ── 分支 B：切到表情 / 扩展
        // 准备尺寸
        let boardH: CGFloat
        let boardView: UIView?
        switch inputState {
        case .emotion:
            boardH = dataSource?.keyboardManagerEmotionBoardHeight(self) ?? EmotionBoardView.boardHeight
            boardView = emotionBoardView
        case .extend:
            // DataSource 给内容高；底部安全区由槽高补上，面板内部再把 PageControl 抬离 Home Indicator
            let contentH = dataSource?.keyboardManagerExtendBoardHeight(self) ?? ExtendBoardView.contentHeight
            boardH = contentH + safeAreaInsetsBottom
            boardView = extendBoardView
        default:
            return
        }

        currentBoardHeight = boardH
        let toH = barH + boardH
        let toY = hostH - toH
        let startFrame = keyboardView.frame
        let startBoardH = max(0, startFrame.height - barH)
        // 已有面板在展示（扩展 ↔ 表情）：槽内钉死只插值高度，禁止再「槽外上滑」否则会像从中部下沉
        // 首次从键盘 / 收起态打开：仍从槽底外上滑
        let isBoardToBoardSwitch = startBoardH > safeAreaInsetsBottom + 1

        // 无动画摆位：起点保持当前外框高度，避免输入条瞬间跳变
        UIView.performWithoutAnimation {
            keyboardView.frame = startFrame
            keyboardView.layoutContent(barHeight: barH, boardHeight: startBoardH, width: width, pinBoardViewInSlot: false)
            keyboardView.displayBoardView(boardView)
            if isBoardToBoardSwitch {
                keyboardView.pinBoardViewToSlot()
            } else {
                keyboardView.placeBoardViewBelowKeyboardView()
            }
            keyboardView.applyBackgroundColor()
            keyboardView.layoutIfNeeded()
        }

        // 动画：槽高插值；板间切换保持贴槽，首次打开再上滑入槽
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            guard let self else { return }
            keyboardView.layoutContent(barHeight: barH, boardHeight: boardH, width: width, pinBoardViewInSlot: false)
            keyboardView.pinBoardViewToSlot()
            keyboardView.frame = CGRect(x: 0, y: toY, width: width, height: toH)
            self.callBackWholeInputViewHeightDidChange(self.callbackHeight(), reason: .boardDidShow)
        }, completion: { _ in
            // 安全区 / 页高在动画结束后才稳定；强制表情板重排删发与遮罩
            boardView?.setNeedsLayout()
            boardView?.layoutIfNeeded()
        })
    }

    // MARK: - 布局与回调

    /// 按当前状态决定槽高（面板 / 键盘 / 安全区）
    private func boardHeightForLayout() -> CGFloat {
        switch inputState {
        case .emotion, .extend:
            return currentBoardHeight
        case .text:
            return 0
        case .normal:
            return inputBarBelowViewController ? 0 : safeAreaInsetsBottom
        }
    }

    /// 对外回调高度（不含底部安全区；系统键盘时与旧逻辑一致）
    private func callbackHeight() -> CGFloat {
        guard let hostView = resolvedHostView, let keyboardView = chatKeyboardView else { return 0 }

        // 藏在屏外且 normal → 业务视为高度 0
        if inputBarBelowViewController && inputState == .normal && currentBoardHeight == 0 {
            return 0
        }

        // 系统键盘：从键盘顶到 VC 底的可见区域（再扣安全区）
        if inputState == .text {
            return hostView.bounds.height - keyboardView.frame.origin.y - safeAreaInsetsBottom
        }

        // 表情 / 扩展 / 常驻 normal：外框高扣安全区
        return max(0, keyboardView.bounds.height - safeAreaInsetsBottom)
    }

    /// 排布 ChatKeyboardView 并设置其在 host 中的 frame
    /// - Parameters:
    ///   - keyboardMinY: 非 nil 时 y 贴系统键盘顶（输入条底对齐键盘顶）
    ///   - placeOffScreen: true 时 y 落在 host 底外（隐藏模式）
    private func layoutChatKeyboardView(barHeight: CGFloat, boardHeight: CGFloat, keyboardMinY: CGFloat? = nil, placeOffScreen: Bool = false) {
        guard let hostView = resolvedHostView, let keyboardView = chatKeyboardView else { return }
        let width = hostView.bounds.width

        // 子视图内容布局
        keyboardView.layoutContent(barHeight: barHeight, boardHeight: boardHeight, width: width)
        keyboardView.applyBackgroundColor()

        // 计算外框 y 并设置 frame
        let height = keyboardView.bounds.height
        let y: CGFloat
        if placeOffScreen {
            y = hostView.bounds.height
        } else if let keyboardMinY {
            y = keyboardMinY
        } else {
            y = hostView.bounds.height - height
        }
        keyboardView.frame = CGRect(x: 0, y: y, width: width, height: height)
    }

    /// 转发 `wholeInputViewHeightDidChange` 给 delegate
    private func callBackWholeInputViewHeightDidChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        delegate?.keyboardManager(self, wholeInputViewHeightDidChange: height, reason: reason)
    }
}