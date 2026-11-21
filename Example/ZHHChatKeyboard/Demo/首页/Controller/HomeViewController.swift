//
//  HomeViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit

/// Example 入口列表页（按标准 / 胶囊 / 聊天 / 其他分组）
final class HomeViewController: UIViewController {

    /// 列表数据
    private let viewModel: HomeViewModel

    /// 场景列表
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // insetGrouped 默认 section 顶 padding 偏大，需配合 header/footer 代理一起压掉
        table.sectionHeaderTopPadding = 0
        return table
    }()

    /// - Parameter viewModel: 首页 ViewModel
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ZHHChatKeyboard"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
    }
}

// MARK: - UI

private extension HomeViewController {

    /// 搭建列表约束
    func setupUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 根据场景 push 对应 Demo 页
    func pushScene(_ scene: DemoSceneKind) {
        let vc: UIViewController
        switch scene {
        case .common: vc = CommonViewController()
        case .commonCustomBoard: vc = CommonCustomBoardViewController()
        case .capsuleLeading: vc = XHSChatViewController()
        case .capsuleTrailing: vc = DouyinChatViewController()
        case .chat: vc = ChatViewController()
        case .moments: vc = MomentsViewController()
        case .submit: vc = SubmitViewController()
        case .pageTextField: vc = PageTextFieldViewController()
        case .darkMode: vc = DarkModeViewController()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        if let scene = viewModel.item(at: indexPath) {
            content.text = scene.title
            content.secondaryText = scene.subtitle
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else if let placeholder = viewModel.placeholderTitle(at: indexPath.section) {
            content.text = placeholder
            content.secondaryText = "后续补充该分组 Demo"
            content.textProperties.color = .secondaryLabel
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat { 32 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = viewModel.group(at: section)?.title else { return nil }
        let header = UITableViewHeaderFooterView()
        var config = header.defaultContentConfiguration()
        config.text = title
        config.textProperties.font = .systemFont(ofSize: 13, weight: .regular)
        config.textProperties.color = .secondaryLabel
        // 首组略收顶边，其余组保持默认呼吸感
        config.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: section == 0 ? 8 : 16,
            leading: 0,
            bottom: 8,
            trailing: 0
        )
        header.contentConfiguration = config
        return header
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { .leastNormalMagnitude }
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat { .leastNormalMagnitude }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let scene = viewModel.item(at: indexPath) else { return }
        pushScene(scene)
    }
}
