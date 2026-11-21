//
//  CommonCustomBoardViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 自定义面板 Demo：DataSource 返回自建 UIView，而不是默认表情 / 扩展板
final class CommonCustomBoardViewController: BaseKeyboardDemoViewController {

    /// 页面状态
    let viewModel = CommonCustomBoardViewModel()
    /// 中间说明文案
    private let label = UILabel()

    override var boardHeight: CGFloat { viewModel.boardHeight }

    override func viewDidLoad() {
        title = "自定义面板"
        super.viewDidLoad()
        view.backgroundColor = .systemIndigo
        setupTipLabel()
    }

    override func makeChatInputBarConfiguration() -> ChatInputBarConfiguration {
        var config = super.makeChatInputBarConfiguration()
        config.voiceButtonHidden = true
        return config
    }

    /// 返回橙色自定义表情面板
    override func makeEmotionBoardView() -> UIView? {
        makeCustomBoardView(
            backgroundColor: .systemOrange,
            text: "这是自定义表情面板\nUIView + UILabel\n高度 \(Int(boardHeight))"
        )
    }

    /// 返回绿色自定义扩展面板
    override func makeExtendBoardView() -> UIView? {
        makeCustomBoardView(
            backgroundColor: .systemGreen,
            text: "这是自定义扩展面板\nUIView + UILabel\n高度 \(Int(boardHeight))"
        )
    }

    /// 自定义表情面板高度
    override func emotionBoardHeight() -> CGFloat { boardHeight }

    /// 自定义扩展面板高度
    override func extendBoardHeight() -> CGFloat { boardHeight }

    override func handleWholeInputHeightChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        label.text = "wholeHeight=\(Int(height)) reason=\(reason.rawValue)\n面板高度=\(Int(boardHeight))"
    }

    override func handleSend(text: String) {
        // 表情面板打开时发送：只清空输入，不收起面板
        label.text = "发送：\(text)"
    }

    override func handleExtendItemSelected(_ item: ExtendBoardItem, at index: Int) {
        label.text = "点击了扩展：\(item.title)"
    }
}

// MARK: - UI

private extension CommonCustomBoardViewController {

    /// 安装中间提示 Label
    func setupTipLabel() {
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.text = viewModel.statusText
        view.insertSubview(label, at: 0)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    /// 创建带说明文案的自定义面板
    /// - Parameters:
    ///   - backgroundColor: 面板背景色
    ///   - text: 居中说明
    /// - Returns: 新创建的面板 View
    func makeCustomBoardView(backgroundColor: UIColor, text: String) -> UIView {
        let board = UIView()
        board.backgroundColor = backgroundColor
        let tip = UILabel()
        tip.numberOfLines = 0
        tip.textAlignment = .center
        tip.textColor = .white
        tip.font = .systemFont(ofSize: 16, weight: .semibold)
        tip.text = text
        board.addSubview(tip)
        tip.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
        return board
    }
}
