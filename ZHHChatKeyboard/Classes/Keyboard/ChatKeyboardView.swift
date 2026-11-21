//
//  ChatKeyboardView.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/16.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 整块聊天键盘区容器（由 `KeyboardManager` 持有，一般业务不直接创建）。
///
/// 职责：
/// - 承载输入条（B）与表情/扩展面板槽（`boardHostView`）
/// - 提供面板上滑/下落的 frame 起点与终点（不用 transform，避免盖住输入条）
/// - 统一背景镂空或实心策略
///
/// 结构：A=自身；B=输入条在上；C/D=表情或扩展面板在 `boardHostView`（B 下方）。
/// 上推动画：面板从槽外（`y = boardHostView.height`）移到槽内（`y = 0`）。
///
/// 用法：由 `KeyboardManager` 调用 `installChatInputBarView`、`layoutContent`、`displayBoardView` 等排布。
open class ChatKeyboardView: UIView {

    // MARK: - 子视图

    /// 底色层；设 clear / `isBackgroundClear` 可做镂空；预留模糊/渐变等扩展
    public let backgroundView = UIView()
    /// 面板容器（表情 / 扩展），位于输入条下方
    public let boardHostView = UIView()
    /// 面板槽顶部分隔线：仅挂上真实面板时显示，安全区垫高时隐藏
    public let boardTopLineView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = ChatKeyboardColor.barSeparator
        return view
    }()
    /// 当前输入条
    public private(set) weak var inputBarView: UIView?

    // MARK: - 外观配置

    /// true 时背景透明（整块镂空）
    public var isBackgroundClear: Bool = false {
        didSet { applyBackgroundColor() }
    }

    /// 实心时的背景色；nil 则跟输入条
    public var solidBackgroundColor: UIColor? {
        didSet { applyBackgroundColor() }
    }

    /// 面板顶线颜色；nil 时用默认分隔线色
    public var boardTopLineColor: UIColor? {
        didSet { boardTopLineView.backgroundColor = boardTopLineColor ?? ChatKeyboardColor.barSeparator }
    }

    // 只读派生

    /// 当前槽里的面板（C 或 D）
    public var currentBoardView: UIView? {
        boardHostView.subviews.first
    }

    // MARK: - 初始化

    /// 创建容器：背景层 + 面板槽 + 槽顶线
    public override init(frame: CGRect) {
        super.init(frame: frame)

        // 子视图层级与裁剪（面板自槽底滑入）
        clipsToBounds = true
        addSubview(backgroundView)
        addSubview(boardHostView)
        addSubview(boardTopLineView)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // 允许面板从 A 底边外往上滑入时先处在槽外
        boardHostView.clipsToBounds = true
    }

    /// 不支持 Storyboard / nib 初始化
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 输入条

    /// 安装输入条（放在顶部，并保证在面板之上）
    /// - Parameter barView: 业务输入条
    public func installChatInputBarView(_ barView: UIView) {
        inputBarView?.removeFromSuperview()
        inputBarView = barView
        addSubview(barView)
        bringSubviewToFront(barView)
        applyBackgroundColor()
    }

    // MARK: - 布局

    /// 按 bar / 面板高度排布子视图（B 在上，槽在下）
    /// - Parameters:
    ///   - barHeight: 输入条高度
    ///   - boardHeight: 面板区高度（无面板时可为安全区高度）
    ///   - width: 宽度
    ///   - pinBoardViewInSlot: true 时把面板钉在槽内；false 时不改面板 frame（留给上推动画）
    public func layoutContent(barHeight: CGFloat, boardHeight: CGFloat, width: CGFloat, pinBoardViewInSlot: Bool = true) {
        let barH = max(0, barHeight)
        let boardH = max(0, boardHeight)
        let h = barH + boardH

        // 自身与背景铺满 bar + 槽
        bounds = CGRect(x: 0, y: 0, width: width, height: h)
        backgroundView.frame = bounds
        boardHostView.frame = CGRect(x: 0, y: barH, width: width, height: boardH)

        // 槽顶 hairline 贴在 B 底
        boardTopLineView.frame = CGRect(x: 0, y: barH, width: width, height: ChatKeyboardCommon.hairlineHeight)

        if let barView = inputBarView {
            barView.frame = CGRect(x: 0, y: 0, width: width, height: barH)
            bringSubviewToFront(barView)
        }
        bringSubviewToFront(boardTopLineView)

        if pinBoardViewInSlot {
            pinBoardViewToSlot()
        }
    }

    // MARK: - 面板显示与动画位姿

    /// 在面板槽中显示指定板；nil 表示清空。挂上后默认在槽内。
    /// - Parameter boardView: 表情或扩展板
    public func displayBoardView(_ boardView: UIView?) {
        // 清空旧板，避免 transform 残留
        boardHostView.subviews.forEach {
            $0.transform = .identity
            $0.removeFromSuperview()
        }
        guard let boardView else {
            boardTopLineView.isHidden = true
            return
        }

        boardView.transform = .identity
        boardView.autoresizingMask = []
        boardHostView.addSubview(boardView)
        pinBoardViewToSlot()

        // 表情面板自带 Tab 底部分割线，与输入条连成一块时不再画槽顶线
        boardTopLineView.isHidden = boardView is EmotionBoardView
        bringSubviewToFront(boardTopLineView)
        if let barView = inputBarView {
            bringSubviewToFront(barView)
        }
    }

    /// 起始态：C/D 顶边贴在 A 底边外（即 boardHostView 底边），整块还在槽外下方
    public func placeBoardViewBelowKeyboardView() {
        guard let boardView = currentBoardView else { return }
        let w = boardHostView.bounds.width
        let h = boardHostView.bounds.height
        boardView.transform = .identity
        boardView.frame = CGRect(x: 0, y: h, width: w, height: h)
    }

    /// 结束态：C/D 落入槽内（顶边贴 B 底）
    public func pinBoardViewToSlot() {
        guard let boardView = currentBoardView else { return }
        boardView.transform = .identity
        boardView.frame = boardHostView.bounds
    }

    /// 收起态：C/D 顶边移到 A 底边外（与 `placeBoardViewBelowKeyboardView` 同位姿）
    public func placeBoardViewBelowKeyboardViewForDismiss() {
        placeBoardViewBelowKeyboardView()
    }

    // MARK: - 背景

    /// 同步背景色（镂空 / 实心 / 跟随输入条）
    public func applyBackgroundColor() {
        if isBackgroundClear {
            backgroundView.backgroundColor = .clear
            backgroundColor = .clear
        } else {
            let color = solidBackgroundColor ?? inputBarView?.backgroundColor ?? ChatKeyboardColor.barBackground
            backgroundView.backgroundColor = color
            backgroundColor = color
        }
    }
}