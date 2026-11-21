//
//  ChatViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 聊天 Demo：推荐写法——列表贴满（顶贴 safeArea），用 `contentInset.bottom` 避开输入区，并滚到底
class ChatViewController: BaseKeyboardDemoViewController {

    /// 消息数据
    let viewModel = ChatViewModel()
    /// 最近一次 Manager 回调高度（不含安全区）；列表晚于键盘安装时补用
    private var lastInputHeight: CGFloat = ChatInputBarView.minHeight

    override var useRightSendButton: Bool { false }

    /// 消息列表
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.keyboardDismissMode = .interactive
        table.separatorStyle = .none
        // 底部留白自己管；顶部靠约束贴 safeArea，不再依赖系统自动 inset
        table.contentInsetAdjustmentBehavior = .never
        table.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseId)
        return table
    }()

    override func viewDidLoad() {
        title = "聊天"
        super.viewDidLoad()
        viewModel.loadSample()
        setupTableView()
        updateListBottom(for: lastInputHeight)
        tableView.reloadData()
        DispatchQueue.main.async { self.scrollToBottom(animated: false) }
    }

    override func handleWholeInputHeightChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        lastInputHeight = height
        updateListBottom(for: height)
        if reason == .boardDidShow || reason == .textDidChange || reason == .textDidSend {
            scrollToBottom(animated: true)
        }
    }

    override func handleSend(text: String) {
        let indexPath = viewModel.appendOutgoing(text)
        tableView.reloadData()
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    /// 滚到最新消息
    /// - Parameter animated: 是否动画
    func scrollToBottom(animated: Bool) {
        let count = viewModel.numberOfItems(in: 0)
        guard count > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .bottom, animated: animated)
    }
}

// MARK: - UI

private extension ChatViewController {

    /// 安装消息列表
    func setupTableView() {
        view.insertSubview(tableView, at: 0)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    /// 按输入区高度更新列表底部 `contentInset`
    /// - Parameter height: Manager 回调高度（不含底部安全区）
    func updateListBottom(for height: CGFloat) {
        let coverHeight = height + view.safeAreaInsets.bottom
        var inset = tableView.contentInset
        inset.bottom = coverHeight
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseId, for: indexPath) as! ChatMessageCell
        if let item = viewModel.item(at: indexPath) {
            cell.configure(item, emotionHelper: keyboardManager.emotionHelper)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {}
