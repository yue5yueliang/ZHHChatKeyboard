//
//  KeyboardBaseManager.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 系统键盘通知基类（`KeyboardManager` 的父类）。
///
/// 职责：
/// - 监听 `keyboardWill/Did` Show/Hide 通知
/// - 从 `userInfo` 解析键盘 frame、动画曲线与时长
/// - 将 `UIView.AnimationCurve` 转为 `UIView.AnimationOptions` 供子类动画使用
///
/// 用法：
/// - 业务侧一般只使用 `KeyboardManager`
/// - 挂载容器优先 `init(hostView:)`；页面场景可用 `init(viewController:)`（内部取 `view`）
open class KeyboardBaseManager: NSObject {

    // MARK: - 公开属性

    /// 输入条 / 面板挂载的容器（弱引用）；`init(hostView:)` 时直接指定
    public weak var hostView: UIView?

    /// 可选宿主 VC（弱引用）；仅 `init(viewController:)` 时写入，便于业务读取
    public weak var viewController: UIViewController?

    /// 解析后的挂载容器：`hostView` 优先，否则 `viewController?.view`
    public var resolvedHostView: UIView? { hostView ?? viewController?.view }

    /// 输入栏高度变化动画时长（秒），默认 0.2
    public var inputBarHeightChangeAnimationDuration: TimeInterval = 0.2

    // MARK: - 初始化

    /// 绑定挂载容器并注册键盘通知
    /// - Parameter hostView: 承载 `ChatKeyboardView` 的容器（须已在 window 层级或即将加入）
    public init(hostView: UIView) {
        self.hostView = hostView
        super.init()
        registerKeyboardNotifications()
    }

    /// 绑定宿主 VC：容器为 `viewController.view`（请在 `view` 已加载后调用，如 `viewDidLoad`）
    /// - Parameter viewController: 宿主控制器
    public convenience init(viewController: UIViewController) {
        self.init(hostView: viewController.view)
        self.viewController = viewController
    }

    /// 析构时移除键盘通知，避免野指针
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 通知注册

    /// 注册 will/did Show/Hide
    private func registerKeyboardNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(onKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(onKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(onKeyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        center.addObserver(self, selector: #selector(onKeyboardDidHideNotification(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    // MARK: - 子类可覆写（Did 钩子）

    /// 键盘已显示（留空钩子，部分系统版本可能收不到 will 时可用）
    @objc open func onKeyboardDidShowNotification(_ notification: Notification) {}

    /// 键盘已隐藏（留空钩子）
    @objc open func onKeyboardDidHideNotification(_ notification: Notification) {}

    // MARK: - 通知入口（私有）

    /// 收到 `keyboardWillShow`，解析 userInfo 后转发子类
    @objc private func onKeyboardWillShowNotification(_ notification: Notification) {
        handleWillNotification(notification, showKeyboard: true)
    }

    /// 收到 `keyboardWillHide`，解析 userInfo 后转发子类
    @objc private func onKeyboardWillHideNotification(_ notification: Notification) {
        handleWillNotification(notification, showKeyboard: false)
    }

    /// 解析通知并转发给子类
    private func handleWillNotification(_ notification: Notification, showKeyboard: Bool) {
        guard let userInfo = notification.userInfo, let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        // 系统键盘动画曲线与时长
        let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeInOut
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25

        // 交给子类（如 KeyboardManager）做布局与状态机
        onKeyboardWillShowOrHide(keyboardRect: keyboardRect, animationOptions: animationOptions(for: curve), duration: duration, showKeyboard: showKeyboard)
    }

    // MARK: - 子类覆写（Will 布局）

    /// 子类覆写：处理键盘将显示/隐藏
    /// - Parameters:
    ///   - keyboardRect: 键盘结束 frame（屏幕坐标）
    ///   - animationOptions: 动画曲线选项
    ///   - duration: 动画时长
    ///   - showKeyboard: true 显示，false 隐藏
    open func onKeyboardWillShowOrHide(keyboardRect: CGRect, animationOptions: UIView.AnimationOptions, duration: Double, showKeyboard: Bool) {}

    // MARK: - 公开工具

    /// 将 UIView.AnimationCurve 转为 UIView.AnimationOptions
    /// - Parameter curve: 系统键盘曲线
    /// - Returns: 动画选项
    public func animationOptions(for curve: UIView.AnimationCurve) -> UIView.AnimationOptions {
        switch curve {
        case .easeInOut: return .curveEaseInOut
        case .easeIn: return .curveEaseIn
        case .easeOut: return .curveEaseOut
        case .linear: return .curveLinear
        @unknown default: return []
        }
    }
}
