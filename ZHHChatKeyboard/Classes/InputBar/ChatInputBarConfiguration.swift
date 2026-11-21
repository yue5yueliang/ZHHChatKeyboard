//
//  ChatInputBarConfiguration.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 布局与语音位置

/// 输入条布局风格
public enum ChatInputBarLayoutStyle: Int {
    /// 普通样式：外置按钮 + 独立白底输入框
    case standard = 0
    /// 胶囊样式：输入与开关按钮共处一体灰底
    case capsule = 1
}

/// 语音按钮相对输入框的位置
public enum ChatInputBarVoicePlacement: Int {
    /// 左侧（普通样式默认；胶囊时语音在左、表情 / + 在右）
    case leading = 0
    /// 右侧、表情左侧（胶囊时语音 / 表情 / + 都在右边）
    case trailing = 1
}

// MARK: - ChatInputBarConfiguration

/// 输入条外观与行为配置（传给 `ChatInputBarView.setup(with:)`，仅生效一次）。
///
/// 职责：
/// - 聚合颜色、图标、自定义子视图与布局风格
/// - 通过工厂方法提供普通 / 胶囊预设
///
/// 用法：
/// - `default()`：普通外置按钮样式
/// - `capsuleLeading()`：一体胶囊，语音在左
/// - `capsuleTrailing()`：一体胶囊，语音 / 表情 / + 全在右
public struct ChatInputBarConfiguration {

    // MARK: - 颜色

    /// 输入条（整条）背景色
    public var inputBarBackgroundColor: UIColor
    /// 顶部分隔线颜色；`.clear` 或胶囊风格时通常不显示线
    public var inputBarBoardColor: UIColor
    /// 输入文字颜色
    public var textColor: UIColor
    /// 输入容器填充色；胶囊风格常设 `.clear` 露出胶囊底
    public var textViewBackgroundColor: UIColor
    /// 「按住说话」标题颜色
    public var recordButtonTitleColor: UIColor

    // MARK: - 图标（nil 用库内默认）

    /// 语音按钮图；nil 用 `ChatKeyboardIcon.voiceSwitch`
    public var voiceSwitchImage: UIImage?
    /// 语音/表情选中后的键盘按钮图；nil 用 `ChatKeyboardIcon.keyboardSwitch`
    public var keyboardSwitchImage: UIImage?
    /// 表情按钮图；nil 用 `ChatKeyboardIcon.emotionSwitch`
    public var emotionSwitchImage: UIImage?
    /// 扩展「+」按钮图；nil 用 `ChatKeyboardIcon.extendSwitch`
    public var extendSwitchImage: UIImage?
    /// 默认「按住说话」正常底图；nil 用 `ChatKeyboardIcon.recordBackground`
    public var recordBackgroundImage: UIImage?
    /// 默认「按住说话」按下底图；nil 用 `ChatKeyboardIcon.recordBackgroundPressed`
    public var recordBackgroundPressedImage: UIImage?

    // MARK: - 自定义视图插槽

    /// 自定义录音区插槽；为 nil 时使用默认「按住说话」按钮
    public var customRecordView: UIView?
    /// 右侧发送按钮；与扩展「+」同时配置时，有字显发送、无字显 +
    public var rightSendButton: UIButton?
    /// 覆盖在输入区上的中心内容（可选）
    public var centerContentView: UIView?
    /// 输入容器内右下角小视图（可选）
    public var inputInsetRightView: UIView?
    /// 自定义输入框；nil 时用内置 `ChatInputTextView`。表情插删 / `normalText` 需为 `ChatInputTextView` 子类
    public var customTextView: UITextView?

    // MARK: - 文案与开关

    /// 「按住说话」文案；nil 时用「按住说话」
    public var speakButtonTitle: String?
    /// 默认输入框 placeholder（仅默认 `ChatInputTextView` 生效）
    public var placeholder: String?
    /// 默认输入框最大字数（`String.count`）；`nil` 不限制，仅默认 `ChatInputTextView` 生效
    public var maxTextLength: Int?
    /// 是否隐藏语音按钮
    public var voiceButtonHidden: Bool
    /// 语音按钮位置；默认左侧。右侧三按钮胶囊用 `.trailing`
    public var voiceButtonPlacement: ChatInputBarVoicePlacement
    /// 是否隐藏扩展「+」
    public var extendButtonHidden: Bool
    /// 是否隐藏表情按钮
    public var emotionButtonHidden: Bool
    /// 是否启用键盘回车发送（走 `onKeyboardSendClick`）
    public var keyboardSendEnabled: Bool
    /// 输入条因换行增高的动画时长（秒）
    public var inputBarHeightChangeAnimationDuration: TimeInterval

    // MARK: - 胶囊布局

    /// 布局风格；默认普通样式
    public var layoutStyle: ChatInputBarLayoutStyle
    /// 胶囊底色（仅 `layoutStyle == .capsule`）
    public var capsuleBackgroundColor: UIColor
    /// 圆角：普通输入容器与胶囊灰底共用（默认 `ChatInputBarView.cornerRadius`）
    public var capsuleCornerRadius: CGFloat
    /// 胶囊相对屏幕左右边距（仅 capsule；条本身仍全宽）
    public var capsuleHorizontalInset: CGFloat
    /// 胶囊相对条顶/底的外边距（仅 capsule；与上方配件 margin 同为 8 时三段间距一致）
    public var capsuleVerticalInset: CGFloat

    // MARK: - 初始化

    /// 创建配置；未传参数使用库默认色与普通布局
    public init(
        inputBarBackgroundColor: UIColor = ChatKeyboardColor.barBackground,
        inputBarBoardColor: UIColor = ChatKeyboardColor.barSeparator,
        textColor: UIColor = ChatKeyboardColor.primaryText,
        textViewBackgroundColor: UIColor = ChatKeyboardColor.inputFill,
        recordButtonTitleColor: UIColor = ChatKeyboardColor.recordTitle,
        voiceSwitchImage: UIImage? = nil,
        keyboardSwitchImage: UIImage? = nil,
        emotionSwitchImage: UIImage? = nil,
        extendSwitchImage: UIImage? = nil,
        recordBackgroundImage: UIImage? = nil,
        recordBackgroundPressedImage: UIImage? = nil,
        customRecordView: UIView? = nil,
        rightSendButton: UIButton? = nil,
        centerContentView: UIView? = nil,
        inputInsetRightView: UIView? = nil,
        customTextView: UITextView? = nil,
        speakButtonTitle: String? = nil,
        placeholder: String? = nil,
        maxTextLength: Int? = nil,
        voiceButtonHidden: Bool = false,
        voiceButtonPlacement: ChatInputBarVoicePlacement = .leading,
        extendButtonHidden: Bool = false,
        emotionButtonHidden: Bool = false,
        keyboardSendEnabled: Bool = true,
        inputBarHeightChangeAnimationDuration: TimeInterval = 0.2,
        layoutStyle: ChatInputBarLayoutStyle = .standard,
        capsuleBackgroundColor: UIColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.22, alpha: 1)
                : UIColor(white: 0.94, alpha: 1)
        },
        capsuleCornerRadius: CGFloat = ChatInputBarView.cornerRadius,
        capsuleHorizontalInset: CGFloat = 12,
        capsuleVerticalInset: CGFloat = 8
    ) {
        // 颜色
        self.inputBarBackgroundColor = inputBarBackgroundColor
        self.inputBarBoardColor = inputBarBoardColor
        self.textColor = textColor
        self.textViewBackgroundColor = textViewBackgroundColor
        self.recordButtonTitleColor = recordButtonTitleColor

        // 图标
        self.voiceSwitchImage = voiceSwitchImage
        self.keyboardSwitchImage = keyboardSwitchImage
        self.emotionSwitchImage = emotionSwitchImage
        self.extendSwitchImage = extendSwitchImage
        self.recordBackgroundImage = recordBackgroundImage
        self.recordBackgroundPressedImage = recordBackgroundPressedImage

        // 自定义视图插槽
        self.customRecordView = customRecordView
        self.rightSendButton = rightSendButton
        self.centerContentView = centerContentView
        self.inputInsetRightView = inputInsetRightView
        self.customTextView = customTextView

        // 文案与开关
        self.speakButtonTitle = speakButtonTitle
        self.placeholder = placeholder
        self.maxTextLength = maxTextLength
        self.voiceButtonHidden = voiceButtonHidden
        self.voiceButtonPlacement = voiceButtonPlacement
        self.extendButtonHidden = extendButtonHidden
        self.emotionButtonHidden = emotionButtonHidden
        self.keyboardSendEnabled = keyboardSendEnabled
        self.inputBarHeightChangeAnimationDuration = inputBarHeightChangeAnimationDuration

        // 胶囊布局
        self.layoutStyle = layoutStyle
        self.capsuleBackgroundColor = capsuleBackgroundColor
        self.capsuleCornerRadius = capsuleCornerRadius
        self.capsuleHorizontalInset = capsuleHorizontalInset
        self.capsuleVerticalInset = capsuleVerticalInset
    }

    // MARK: - 工厂预设

    /// 默认普通样式（外置按钮 + 独立输入框）
    public static func `default`() -> ChatInputBarConfiguration {
        ChatInputBarConfiguration()
    }

    /// 一体胶囊 + 透明输入区：语音在左，表情 / + 在右
    public static func capsuleLeading() -> ChatInputBarConfiguration {
        ChatInputBarConfiguration(
            inputBarBackgroundColor: ChatKeyboardColor.inputFill,
            inputBarBoardColor: .clear,
            textViewBackgroundColor: .clear,
            placeholder: "发消息...",
            layoutStyle: .capsule,
            // 与上方快捷短语左缘对齐时常用约 18
            capsuleHorizontalInset: 18,
            capsuleVerticalInset: 8
        )
    }

    /// 一体胶囊：语音 / 表情 / + 全在右侧
    public static func capsuleTrailing() -> ChatInputBarConfiguration {
        ChatInputBarConfiguration(
            inputBarBackgroundColor: ChatKeyboardColor.inputFill,
            inputBarBoardColor: .clear,
            textViewBackgroundColor: .clear,
            placeholder: "输入你的问题..",
            voiceButtonPlacement: .trailing,
            layoutStyle: .capsule,
            capsuleHorizontalInset: 12,
            capsuleVerticalInset: 8
        )
    }
}
