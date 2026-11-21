//
//  CommonViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 普通常驻输入栏 Demo：底部常驻 InputBar，切换系统键盘 / 表情 / 扩展
class CommonViewController: BaseKeyboardDemoViewController {

    /// 页面状态与输入条开关配置
    let viewModel = CommonViewModel()
    /// 中间说明 / 高度回调文案
    let label = UILabel()
    /// 配置开关列表
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    /// 配置表高度（按内容自适应，避免最后一行被裁切）
    private var tableHeightConstraint: Constraint?
    /// QK 风格：VC 上跟随 wholeHeight 的红块（不在输入条内）
    private let heightFollowRedBlock = UIView()
    /// 最近一次整块输入区高度（开关打开时立刻定位用）
    private var lastWholeInputHeight: CGFloat = 0

    private static let redBlockSize = CGSize(width: 200, height: 100)

    fileprivate enum ConfigRow: Int, CaseIterable {
        case voice
        case emotion
        case extend
        case keyboardSend
        case rightSend
        case topCustomView
        case heightFollowRedBlock

        var title: String {
            switch self {
            case .voice: return "显示语音按钮"
            case .emotion: return "显示表情按钮"
            case .extend: return "显示更多按钮"
            case .keyboardSend: return "启用键盘发送"
            case .rightSend: return "右侧发送按钮"
            case .topCustomView: return "输入框下回复 View"
            case .heightFollowRedBlock: return "高度回调红块"
            }
        }
    }

    override var boardHeight: CGFloat { EmotionBoardView.boardHeight }
    override var useRightSendButton: Bool { viewModel.showRightSendButton }

    override func viewDidLoad() {
        title = "普通常驻"
        super.viewDidLoad()
        // insetGrouped 圆角卡片需要灰底衬托；基类默认 systemBackground 会糊效果
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "隐藏键盘",
            style: .plain,
            target: self,
            action: #selector(hideKeyboardTapped)
        )
        setupTipLabel()
        setupConfigTable()
        setupHeightFollowRedBlock()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshConfigTableHeight()
        if viewModel.showHeightFollowRedBlock {
            layoutHeightFollowRedBlock(wholeHeight: lastWholeInputHeight)
        }
    }

    override func makeChatInputBarConfiguration() -> ChatInputBarConfiguration {
        var config = super.makeChatInputBarConfiguration()
        config.voiceButtonHidden = !viewModel.showVoiceButton
        config.emotionButtonHidden = !viewModel.showEmotionButton
        config.extendButtonHidden = !viewModel.showExtendButton
        config.keyboardSendEnabled = viewModel.keyboardSendEnabled
        return config
    }

    override func handleWholeInputHeightChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        lastWholeInputHeight = height
        label.text = "wholeHeight=\(Int(height)) reason=\(reason.rawValue)\n表情=\(Int(emotionBoardHeight())) 扩展=\(Int(extendBoardHeight()))"
        // 回调已在动画 block 内，直接改 frame 即可跟着动
        if viewModel.showHeightFollowRedBlock {
            layoutHeightFollowRedBlock(wholeHeight: height)
        }
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

private extension CommonViewController {

    /// 安装中间提示 Label
    func setupTipLabel() {
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 13)
        label.text = viewModel.statusText
        view.insertSubview(label, at: 0)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-120)
        }
    }

    /// 顶部配置开关表
    func setupConfigTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemGroupedBackground
        tableView.isScrollEnabled = true
        tableView.alwaysBounceVertical = true
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 48
        tableView.estimatedRowHeight = 48
        // insetGrouped 默认 sectionHeaderTopPadding 偏大，收紧 header 上方空白
        tableView.sectionHeaderTopPadding = 0
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "config")
        view.insertSubview(tableView, at: 0)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            tableHeightConstraint = make.height.equalTo(480).constraint
        }
    }

    /// QK debugLeftBottomView：挂在 VC.view，不进输入条
    func setupHeightFollowRedBlock() {
        // 红块全程 frame 排布；内部也不要用 SnapKit，避免 width=0 时约束冲突
        let size = Self.redBlockSize
        heightFollowRedBlock.frame = CGRect(origin: .zero, size: size)
        heightFollowRedBlock.backgroundColor = .systemRed
        heightFollowRedBlock.isHidden = true
        heightFollowRedBlock.isUserInteractionEnabled = false

        let title = UILabel(frame: heightFollowRedBlock.bounds.insetBy(dx: 8, dy: 8))
        title.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        title.text = "高度回调红块\n（不在条上）"
        title.textColor = .white
        title.font = .systemFont(ofSize: 13, weight: .medium)
        title.numberOfLines = 0
        title.textAlignment = .center
        heightFollowRedBlock.addSubview(title)

        view.addSubview(heightFollowRedBlock)
    }

    /// 对齐 QK：y = viewH - wholeHeight - blockH - safeBottom
    func layoutHeightFollowRedBlock(wholeHeight: CGFloat) {
        let size = Self.redBlockSize
        let safeBottom = view.safeAreaInsets.bottom
        let y = view.bounds.height - wholeHeight - size.height - safeBottom
        heightFollowRedBlock.frame = CGRect(x: 0, y: y, width: size.width, height: size.height)
        view.bringSubviewToFront(heightFollowRedBlock)
    }

    /// 按 contentSize 撑开，保证分组卡片完整可见
    func refreshConfigTableHeight() {
        tableView.layoutIfNeeded()
        let contentH = tableView.contentSize.height
        guard contentH > 0 else { return }
        let maxH = view.bounds.height * 0.55
        let target = min(max(contentH, 1), max(maxH, 360))
        tableHeightConstraint?.update(offset: target)
        tableView.isScrollEnabled = contentH > target + 1
    }

    func isOn(for row: ConfigRow) -> Bool {
        switch row {
        case .voice: return viewModel.showVoiceButton
        case .emotion: return viewModel.showEmotionButton
        case .extend: return viewModel.showExtendButton
        case .keyboardSend: return viewModel.keyboardSendEnabled
        case .rightSend: return viewModel.showRightSendButton
        case .topCustomView: return viewModel.showTopCustomView
        case .heightFollowRedBlock: return viewModel.showHeightFollowRedBlock
        }
    }

    func setOn(_ on: Bool, for row: ConfigRow) {
        switch row {
        case .voice: viewModel.showVoiceButton = on
        case .emotion: viewModel.showEmotionButton = on
        case .extend: viewModel.showExtendButton = on
        case .keyboardSend: viewModel.keyboardSendEnabled = on
        case .rightSend: viewModel.showRightSendButton = on
        case .topCustomView: viewModel.showTopCustomView = on
        case .heightFollowRedBlock: viewModel.showHeightFollowRedBlock = on
        }

        switch row {
        case .topCustomView:
            applyTopCustomView()
        case .heightFollowRedBlock:
            applyHeightFollowRedBlock()
        default:
            rebuildChatInputBar()
            applyTopCustomView()
        }
    }

    /// 用 `showReplyView` / `hideReplyView` 演示输入框下方回复条
    func applyTopCustomView() {
        guard chatInputBarView != nil else { return }
        if viewModel.showTopCustomView {
            let reply = makeDemoReplyView()
            chatInputBarView.showReplyView(reply, marginTop: 6, marginBottom: 8)
        } else {
            chatInputBarView.hideReplyView()
        }
    }

    /// 显示 / 隐藏 VC 上的高度跟随红块
    func applyHeightFollowRedBlock() {
        heightFollowRedBlock.isHidden = !viewModel.showHeightFollowRedBlock
        if viewModel.showHeightFollowRedBlock {
            layoutHeightFollowRedBlock(wholeHeight: lastWholeInputHeight)
        }
    }

    /// Demo 回复条（宽度由库按输入容器对齐；右侧关闭可收起）
    func makeDemoReplyView() -> UIView {
        let height: CGFloat = 32
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: height))
        container.backgroundColor = UIColor.secondarySystemFill
        container.layer.cornerRadius = 6
        container.clipsToBounds = true

        let close = DemoReplyCloseButton.make(
            rowHeight: height,
            containerWidth: container.bounds.width,
            target: self,
            action: #selector(replyCloseTapped)
        )
        container.addSubview(close)

        let leading = DemoReplyCloseButton.labelLeading
        let titleW = DemoReplyCloseButton.labelMaxX(containerWidth: container.bounds.width) - leading
        let title = UILabel(frame: CGRect(x: leading, y: 0, width: max(0, titleW), height: height))
        title.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        title.text = "回复示例（对齐输入框）"
        title.textColor = .secondaryLabel
        title.font = .systemFont(ofSize: 13)
        container.addSubview(title)
        return container
    }

    /// 点回复条关闭：收起 View，并同步关掉配置开关
    @objc func replyCloseTapped() {
        guard viewModel.showTopCustomView else { return }
        viewModel.showTopCustomView = false
        chatInputBarView.hideReplyView()
        if let row = ConfigRow.allCases.firstIndex(of: .topCustomView) {
            let indexPath = IndexPath(row: row, section: 0)
            if let cell = tableView.cellForRow(at: indexPath),
               let toggle = cell.accessoryView as? UISwitch {
                toggle.setOn(false, animated: true)
            }
        }
    }
}

// MARK: - UITableView

extension CommonViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ConfigRow.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "输入条配置"
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        32
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "config", for: indexPath)
        let row = ConfigRow(rawValue: indexPath.row) ?? .voice
        var content = cell.defaultContentConfiguration()
        content.text = row.title
        cell.contentConfiguration = content
        cell.selectionStyle = .none

        let toggle = UISwitch()
        toggle.isOn = isOn(for: row)
        toggle.tag = row.rawValue
        toggle.addTarget(self, action: #selector(configSwitchChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    @objc func configSwitchChanged(_ sender: UISwitch) {
        guard let row = ConfigRow(rawValue: sender.tag) else { return }
        setOn(sender.isOn, for: row)
    }

    @objc func hideKeyboardTapped() {
        keyboardManager.hideAllBoardView()
    }
}
