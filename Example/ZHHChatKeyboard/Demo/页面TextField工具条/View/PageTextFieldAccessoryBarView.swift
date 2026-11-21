//
//  PageTextFieldAccessoryBarView.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/19/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import SnapKit
import ZHHChatKeyboard

/// 键盘上方轻量工具条：无输入框，仅快捷入口（对齐 QK TextField CustomBarView）
final class PageTextFieldAccessoryBarView: UIView {

    /// 点击表情按钮
    var onEmotionTap: ((UIButton) -> Void)?

    /// 默认高度
    static let preferredHeight: CGFloat = 56

    private let topLine = UIView()
    private let avatarStack = UIStackView()
    private let emotionButton = UIButton(type: .custom)

    /// 表情按钮选中态（面板打开时为 true）
    var isEmotionSelected: Bool {
        get { emotionButton.isSelected }
        set { emotionButton.isSelected = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI

private extension PageTextFieldAccessoryBarView {

    func setupUI() {
        backgroundColor = ChatKeyboardColor.barBackground
        autoresizingMask = [.flexibleWidth, .flexibleTopMargin]

        topLine.backgroundColor = ChatKeyboardColor.barSeparator
        addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        avatarStack.axis = .horizontal
        avatarStack.spacing = 10
        avatarStack.alignment = .center
        addSubview(avatarStack)
        avatarStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }

        for (index, color) in [UIColor.systemBlue, UIColor.systemPink].enumerated() {
            let avatar = makeAvatarView(color: color, title: index == 0 ? "A" : "B")
            avatarStack.addArrangedSubview(avatar)
            avatar.snp.makeConstraints { make in
                make.size.equalTo(36)
            }
        }

        let emotionImage = ChatKeyboardIcon.emotionSwitch
        let keyboardImage = ChatKeyboardIcon.keyboardSwitch
        emotionButton.setImage(emotionImage, for: .normal)
        emotionButton.setImage(keyboardImage, for: .selected)
        emotionButton.addTarget(self, action: #selector(emotionTapped), for: .touchUpInside)
        addSubview(emotionButton)
        emotionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
    }

    func makeAvatarView(color: UIColor, title: String) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = 18
        view.clipsToBounds = true

        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }

    @objc func emotionTapped() {
        emotionButton.isSelected.toggle()
        onEmotionTap?(emotionButton)
    }
}
