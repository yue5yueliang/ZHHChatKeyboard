//
//  EmotionHelperTests.swift
//  ZHHChatKeyboard
//
//  Created by 桃色三岁 on 2026/11/12.
//  Copyright © 2026 桃色三岁. All rights reserved.
//

import XCTest
@testable import ZHHChatKeyboard
import UIKit

final class EmotionHelperTests: XCTestCase {

    func testAttributedStringKeepsPlainTextWhenNoMatch() {
        let helper = EmotionHelper()
        helper.emotionArray = []
        let font = UIFont.systemFont(ofSize: 16)
        let result = helper.attributedString(from: "hello world", font: font)
        XCTAssertEqual(result.string, "hello world")
    }

    func testNormalTextExportsAttachmentDisplayText() {
        let textView = ChatInputTextView()
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .black
        let attachment = EmotionAttachment()
        attachment.displayText = "[微笑]"
        attachment.image = UIImage()
        attachment.bounds = CGRect(x: 0, y: 0, width: 16, height: 16)
        textView.attributedText = NSAttributedString(attachment: attachment)
        XCTAssertEqual(textView.normalText, "[微笑]")
    }

    func testDeleteEmotionReturnsFalseAtStart() {
        let textView = ChatInputTextView()
        textView.text = ""
        textView.selectedRange = NSRange(location: 0, length: 0)
        XCTAssertFalse(textView.deleteEmotion())
    }
}
