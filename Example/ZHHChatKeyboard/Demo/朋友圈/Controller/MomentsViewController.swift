//
//  MomentsViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 朋友圈 Demo：默认隐藏输入条；右上角可切换常驻 / 隐藏
class MomentsViewController: BaseKeyboardDemoViewController {

    /// 动态列表数据
    let viewModel = MomentsViewModel()
    /// false=平时藏起（belowVC）；true=输入条常驻底部
    private var isInputBarResident = false

    /// 动态 / 评论列表
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        // 拖动列表时收起键盘 / 面板
        table.keyboardDismissMode = .onDrag
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()

    override var belowViewControllerMode: Bool { !isInputBarResident }

    override func viewDidLoad() {
        title = "朋友圈"
        super.viewDidLoad()
        setupTableView()
        refreshResidentBarButton()
    }

    override func handleWholeInputHeightChange(_ height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        var inset = tableView.contentInset
        inset.bottom = height
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }

    override func handleSend(text: String) {
        viewModel.insertOutgoing(text)
        tableView.reloadData()
        keyboardManager.hideAllBoardView()
    }
}

// MARK: - UI

private extension MomentsViewController {

    /// 安装列表与收起手势
    func setupTableView() {
        view.insertSubview(tableView, at: 0)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTableBackgroundTap(_:)))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }

    /// 右上角：常驻 ↔ 隐藏
    func refreshResidentBarButton() {
        let title = isInputBarResident ? "改为隐藏" : "改为常驻"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: title,
            style: .plain,
            target: self,
            action: #selector(toggleInputBarResident)
        )
    }

    /// 切换输入条常驻 / 平时隐藏，并重建底部键盘区
    @objc func toggleInputBarResident() {
        isInputBarResident.toggle()
        refreshResidentBarButton()
        keyboardManager.addBottomChatInputBarView(chatInputBarView, belowViewController: belowViewControllerMode)
        keyboardManager.bindTextView(chatInputBarView.inputTextView)
        title = isInputBarResident ? "朋友圈 · 常驻" : "朋友圈"
    }

    /// 点在 cell 上不收键盘（否则会先藏再弹，换一条评论时闪一下）；只有点空白才收起
    @objc func handleTableBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: tableView)
        if tableView.indexPathForRow(at: point) != nil { return }
        keyboardManager.hideAllBoardView()
    }
}

// MARK: - UITableViewDataSource

extension MomentsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = viewModel.item(at: indexPath.row)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MomentsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 已在输入时只滚到对应行，避免重复 becomeFirstResponder 触发系统键盘闪断
        if chatInputBarView.inputTextView.isFirstResponder == false {
            chatInputBarView.textViewBecomeFirstResponder()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}
