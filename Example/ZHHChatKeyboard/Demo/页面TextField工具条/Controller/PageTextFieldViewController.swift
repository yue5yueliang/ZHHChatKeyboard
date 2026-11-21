//
//  PageTextFieldViewController.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/19/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 页面上有 TextField；键盘上方挂无输入框的自定义工具条（非输入条改 TextField）
final class PageTextFieldViewController: UIViewController {

    private let viewModel = PageTextFieldViewModel()
    private var keyboardManager: KeyboardManager!
    private let accessoryBar = PageTextFieldAccessoryBarView()
    private let textField = UITextField()
    private let hideButton = UIButton(type: .system)
    private let tipLabel = UILabel()
    private let emotionBoardView = EmotionBoardView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "页面 TextField"
        view.backgroundColor = UIColor(red: 248 / 255, green: 248 / 255, blue: 246 / 255, alpha: 1)
        emotionBoardView.delegate = self
        emotionBoardView.imageLoader = DemoEmotionGIFLoader.shared
        setupUI()
        setupAccessoryActions()
        setupKeyboardManager()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager.viewControllerWillDisappear = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardManager.viewControllerWillDisappear = false
    }
}

// MARK: - UI & 组装

private extension PageTextFieldViewController {

    func setupUI() {
        textField.borderStyle = .roundedRect
        textField.placeholder = viewModel.placeholder
        textField.font = .systemFont(ofSize: 16)
        textField.returnKeyType = .done
        textField.delegate = self
        view.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }

        hideButton.setTitle("点我隐藏键盘", for: .normal)
        hideButton.titleLabel?.font = .systemFont(ofSize: 16)
        hideButton.addTarget(self, action: #selector(hideKeyboard), for: .touchUpInside)
        view.addSubview(hideButton)
        hideButton.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .center
        tipLabel.textColor = .secondaryLabel
        tipLabel.font = .systemFont(ofSize: 13)
        tipLabel.text = viewModel.tipText
        view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(hideButton.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        accessoryBar.frame = CGRect(x: 0, y: 0, width: width, height: PageTextFieldAccessoryBarView.preferredHeight)
    }

    func setupAccessoryActions() {
        accessoryBar.onEmotionTap = { [weak self] button in
            guard let self else { return }
            if button.isSelected {
                self.keyboardManager.switchToEmotionBoard()
            } else {
                self.textField.becomeFirstResponder()
            }
        }
    }

    func setupKeyboardManager() {
        keyboardManager = KeyboardManager(viewController: self)
        keyboardManager.dataSource = self
        keyboardManager.delegate = self
        // 平时藏起；键盘弹起时工具条贴在键盘上方
        keyboardManager.addBottomChatInputBarView(accessoryBar, belowViewController: true)
        keyboardManager.bindTextView(textField)
    }

    @objc func hideKeyboard() {
        accessoryBar.isEmotionSelected = false
        keyboardManager.hideAllBoardView()
    }
}

// MARK: - UITextFieldDelegate

extension PageTextFieldViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        accessoryBar.isEmotionSelected = false
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }
}

// MARK: - KeyboardManagerDataSource

extension PageTextFieldViewController: KeyboardManagerDataSource {

    func keyboardManagerEmotionBoardView(_ manager: KeyboardManager) -> UIView? { emotionBoardView }
    func keyboardManagerExtendBoardView(_ manager: KeyboardManager) -> UIView? { nil }
    func keyboardManagerEmotionBoardHeight(_ manager: KeyboardManager) -> CGFloat { EmotionBoardView.boardHeight }
    func keyboardManagerExtendBoardHeight(_ manager: KeyboardManager) -> CGFloat { 0 }
    func keyboardManagerEmotionGroups(_ manager: KeyboardManager) -> [EmotionGroup] {
        DemoEmotionCatalog.makeGroups()
    }
}

// MARK: - KeyboardManagerDelegate

extension PageTextFieldViewController: KeyboardManagerDelegate {

    func keyboardManager(_ manager: KeyboardManager, wholeInputViewHeightDidChange height: CGFloat, reason: WholeInputViewHeightChangeReason) {
        tipLabel.text = "工具条贴键盘；wholeHeight=\(Int(height)) reason=\(reason.rawValue)"
    }
}

// MARK: - EmotionBoardViewDelegate

extension PageTextFieldViewController: EmotionBoardViewDelegate {

    func emotionView(_ view: EmotionBoardView, didSelect emotion: Emotion, at index: Int, in group: EmotionGroup) {
        switch group.tapAction {
        case .sendDirectly:
            tipLabel.text = "直发贴纸：\(emotion.displayName)"
        case .insertIntoInput:
            // TextField 只能插纯文本 displayName
            textField.insertText(emotion.displayName)
        }
    }

    func emotionViewDidSelectAddButton(_ view: EmotionBoardView, in group: EmotionGroup) {
        DemoEmotionAddPresenter.present(from: self, board: view)
    }

    func emotionViewDidSelectDeleteButton(_ view: EmotionBoardView) {
        textField.deleteBackward()
    }

    func emotionViewDidSelectSendButton(_ view: EmotionBoardView) {
        let text = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        tipLabel.text = text.isEmpty ? "内容为空" : "提交：\(text)"
        if !text.isEmpty {
            textField.text = nil
        }
        hideKeyboard()
    }
}
