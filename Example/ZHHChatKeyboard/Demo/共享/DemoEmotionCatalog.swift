//
//  DemoEmotionCatalog.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 11/12/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import Photos
import UIKit
import ZHHChatKeyboard

/// Example 演示用表情目录。
/// - Important: 资源仅供 Demo 预览，**不可用于商用**；正式接入请通过 `KeyboardManagerDataSource.keyboardManagerEmotionGroups` 注入自有授权表情组。
enum DemoEmotionCatalog {

    /// 资源名与展示名对照（Example Bundle 内 ic_emoji_*）
    private static let namePairs: [(String, String)] = [
        ("ic_emoji_smile", "[微笑]"), ("ic_emoji_grimace", "[撇嘴]"), ("ic_emoji_drool", "[色]"),
        ("ic_emoji_blank", "[发呆]"), ("ic_emoji_proud", "[得意]"), ("ic_emoji_sob", "[流泪]"),
        ("ic_emoji_shy", "[害羞]"), ("ic_emoji_silent", "[闭嘴]"), ("ic_emoji_sleep", "[睡]"),
        ("ic_emoji_cry", "[大哭]"), ("ic_emoji_awkward", "[尴尬]"), ("ic_emoji_angry", "[发怒]"),
        ("ic_emoji_tongue", "[调皮]"), ("ic_emoji_grin", "[呲牙]"), ("ic_emoji_surprise", "[惊讶]"),
        ("ic_emoji_sad", "[难过]"), ("ic_emoji_crazy", "[抓狂]"), ("ic_emoji_puke", "[吐]"),
        ("ic_emoji_chuckle", "[偷笑]"), ("ic_emoji_joyful", "[愉快]"), ("ic_emoji_side_eye", "[白眼]"),
        ("ic_emoji_arrogant", "[傲慢]"), ("ic_emoji_sleepy", "[困]"), ("ic_emoji_panic", "[惊恐]"),
        ("ic_emoji_silly_smile", "[憨笑]"), ("ic_emoji_leisure", "[悠闲]"), ("ic_emoji_curse", "[咒骂]"),
        ("ic_emoji_doubt", "[疑问]"), ("ic_emoji_shush", "[嘘]"), ("ic_emoji_dizzy", "[晕]"),
        ("ic_emoji_toasted", "[衰]"), ("ic_emoji_skull", "[骷髅]"), ("ic_emoji_hammer", "[敲打]"),
        ("ic_emoji_bye", "[再见]"), ("ic_emoji_wipe_sweat", "[擦汗]"), ("ic_emoji_pick_nose", "[抠鼻]"),
        ("ic_emoji_clap", "[鼓掌]"), ("ic_emoji_smug", "[坏笑]"), ("ic_emoji_humph_right", "[右哼哼]"),
        ("ic_emoji_disdain", "[鄙视]"), ("ic_emoji_wronged", "[委屈]"), ("ic_emoji_almost_cry", "[快哭了]"),
        ("ic_emoji_sly", "[阴险]"), ("ic_emoji_kiss", "[亲亲]"), ("ic_emoji_pitiful", "[可怜]"),
        ("ic_emoji_yeah", "[耶]"), ("ic_emoji_chill", "[吃瓜]"), ("ic_emoji_add_oil", "[加油]"),
        ("ic_emoji_sweat", "[汗]"), ("ic_emoji_oh_my", "[天啊]"), ("ic_emoji_emm", "[Emm]"),
        ("ic_emoji_social", "[社会社会]"), ("ic_emoji_doge", "[旺柴]"), ("ic_emoji_no_prob", "[好的]"),
        ("ic_emoji_slap", "[打脸]"), ("ic_emoji_roll_eyes", "[翻白眼]"), ("ic_emoji_awesome", "[666]"),
        ("ic_emoji_let_me_see", "[让我看看]"), ("ic_emoji_sigh", "[叹气]"), ("ic_emoji_bitter", "[苦涩]"),
        ("ic_emoji_crack", "[裂开]"), ("ic_emoji_lips", "[嘴唇]"), ("ic_emoji_heart", "[爱心]"),
        ("ic_emoji_broken_heart", "[心碎]"), ("ic_emoji_hug", "[拥抱]"), ("ic_emoji_thumbs_up", "[强]"),
        ("ic_emoji_thumbs_down", "[弱]"), ("ic_emoji_handshake", "[握手]"), ("ic_emoji_victory", "[胜利]"),
        ("ic_emoji_salute", "[抱拳]"), ("ic_emoji_beckon", "[勾引]"), ("ic_emoji_fist", "[拳头]"),
        ("ic_emoji_ok", "[OK]"), ("ic_emoji_beer", "[啤酒]"), ("ic_emoji_coffee", "[咖啡]"),
        ("ic_emoji_cake", "[蛋糕]"), ("ic_emoji_rose", "[玫瑰]"), ("ic_emoji_wilt", "[凋谢]"),
        ("ic_emoji_cleaver", "[菜刀]"), ("ic_emoji_bomb", "[炸弹]"), ("ic_emoji_poop", "[便便]"),
        ("ic_emoji_moon", "[月亮]"), ("ic_emoji_sun", "[太阳]"), ("ic_emoji_gift", "[礼物]"),
        ("ic_emoji_red_packet", "[红包]"), ("ic_emoji_pig", "[猪头]"), ("ic_emoji_jump", "[跳跳]"),
        ("ic_emoji_shake", "[发抖]"), ("ic_emoji_spin", "[转圈]")
    ]

    /// 表情包索引（只列资源名，不含 `.json`）
    private static let packsIndexFileName = "demo_emotion_packs"
}

// MARK: - 对外 API

extension DemoEmotionCatalog {

    /// Demo 默认小表情列表（仅 Example；写入输入框）
    static func makeEmotions() -> [Emotion] {
        makeEmotions(from: namePairs)
    }

    private static func makeEmotions(from pairs: [(String, String)]) -> [Emotion] {
        pairs.map {
            Emotion(
                identifier: $0.0,
                displayName: $0.1,
                image: UIImage(named: $0.0),
                accessibilityLabel: String($0.1.dropFirst().dropLast())
            )
        }
    }

    /// Demo 表情组：1 默认小表情 → 2 自定义（含加号）→ 3 起表情包
    static func makeGroups() -> [EmotionGroup] {
        let emotionTabIcon = UIImage(named: "ic_tab_emotion")
        let likeTabIcon = UIImage(named: "ic_tab_like")

        var urlMap: [String: URL] = [:]
        var groups: [EmotionGroup] = [
            EmotionGroup(
                identifier: "demo.default",
                title: "表情",
                icon: emotionTabIcon,
                style: .emoji,
                tapAction: .insertIntoInput,
                emotions: makeEmotions()
            ),
            makeCustomGroup(icon: likeTabIcon, urlMap: &urlMap)
        ]

        for pack in loadIndexedPacks() {
            let emotions: [Emotion] = pack.items.compactMap { item in
                guard let url = makeURL(from: item.url) else { return nil }
                urlMap[item.id] = url
                return Emotion(
                    identifier: item.id,
                    displayName: item.name,
                    image: nil,
                    accessibilityLabel: item.name.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                )
            }
            guard !emotions.isEmpty else { continue }
            groups.append(
                EmotionGroup(
                    identifier: pack.identifier.isEmpty ? pack.fileName : pack.identifier,
                    title: pack.title.isEmpty ? pack.fileName : pack.title,
                    icon: likeTabIcon,
                    style: .sticker,
                    tapAction: .sendDirectly,
                    emotions: emotions,
                    showsAddButton: false,
                    showsItemTitles: false
                )
            )
        }
        DemoEmotionGIFLoader.shared.register(urlByIdentifier: urlMap)
        return groups
    }

    /// 自定义表情组（首格加号；数据来自本地 Demo 存储）
    private static func makeCustomGroup(icon: UIImage?, urlMap: inout [String: URL]) -> EmotionGroup {
        let emotions: [Emotion] = DemoCustomStickersStore.load().compactMap { item in
            if let fileURL = item.fileURL, let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                return Emotion(
                    identifier: item.id,
                    displayName: item.name,
                    image: image,
                    accessibilityLabel: item.name
                )
            }
            guard let raw = item.remoteURL, let url = makeURL(from: raw) else { return nil }
            urlMap[item.id] = url
            return Emotion(
                identifier: item.id,
                displayName: item.name,
                image: nil,
                accessibilityLabel: item.name
            )
        }
        return EmotionGroup(
            identifier: DemoCustomStickersStore.groupIdentifier,
            title: "自定义",
            icon: icon,
            style: .sticker,
            tapAction: .sendDirectly,
            emotions: emotions,
            showsAddButton: true,
            showsItemTitles: false
        )
    }

    /// 读索引，再按顺序加载各 `demo_pack_*.json`
    private static func loadIndexedPacks() -> [DemoEmotionPack] {
        let names = loadPackFileNames()
        return names.compactMap { loadPack(fileName: $0) }
    }

    private static func loadPackFileNames() -> [String] {
        guard
            let url = Bundle.main.url(forResource: packsIndexFileName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let index = try? JSONDecoder().decode(DemoEmotionPacksIndex.self, from: data)
        else {
            return []
        }
        return index.packs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { name in
                name.hasSuffix(".json") ? String(name.dropLast(5)) : name
            }
    }

    private static func loadPack(fileName: String) -> DemoEmotionPack? {
        guard
            let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let pack = try? JSONDecoder().decode(DemoEmotionPackPayload.self, from: data)
        else {
            return nil
        }
        return DemoEmotionPack(
            fileName: fileName,
            identifier: pack.identifier,
            title: pack.title,
            items: pack.items
        )
    }

    /// QQ 图床等 URL 含 `*` 等字符时，优先原样解析，失败再做一次编码；http 升为 https
    private static func makeURL(from raw: String) -> URL? {
        let normalized: String = {
            if raw.lowercased().hasPrefix("http://") {
                return "https://" + raw.dropFirst("http://".count)
            }
            return raw
        }()
        if let url = URL(string: normalized) { return url }
        guard let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else { return nil }
        return URL(string: encoded)
    }

    /// Demo「更多」入口（群聊线稿图标）
    static func makeExtendBoardItems() -> [ExtendBoardItem] {
        [
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_album"), title: "相册"),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_camera"), title: "拍摄"),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_video"), title: "视频通话"),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_location"), title: "位置"),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_pay"), title: "转账", badgeText: ""),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_favorite"), title: "收藏"),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_friendcard"), title: "名片"),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_wallet"), title: "钱包"),
            ExtendBoardItem(icon: UIImage(named: "ic_keyboard_voice"), title: "语音输入")
        ]
    }
}

// MARK: - JSON 模型

private struct DemoEmotionPacksIndex: Decodable {
    var packs: [String]
}

private struct DemoEmotionPackPayload: Decodable {
    var identifier: String
    var title: String
    var items: [DemoEmotionPackItem]
}

private struct DemoEmotionPackItem: Decodable {
    var id: String
    var name: String
    var url: String
}

private struct DemoEmotionPack {
    var fileName: String
    var identifier: String
    var title: String
    var items: [DemoEmotionPackItem]
}

// MARK: - 自定义表情本地存储（Demo）

enum DemoCustomStickersStore {
    static let groupIdentifier = "demo.custom.favorites"
    private static let storageKey = "demo.custom.stickers.items"

    struct Item: Codable {
        var id: String
        var name: String
        var remoteURL: String?
        var localFileName: String?

        var fileURL: URL? {
            guard let localFileName else { return nil }
            return directory.appendingPathComponent(localFileName)
        }
    }

    private static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("DemoCustomStickers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func load() -> [Item] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let items = try? JSONDecoder().decode([Item].self, from: data)
        else { return [] }
        return items
    }

    static func save(_ items: [Item]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func appendRemoteURL(_ raw: String, name: String? = nil) -> Item? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let item = Item(
            id: "custom.\(Int(Date().timeIntervalSince1970 * 1000))",
            name: (name?.isEmpty == false ? name! : "自定义"),
            remoteURL: trimmed,
            localFileName: nil
        )
        var items = load()
        items.insert(item, at: 0)
        save(items)
        return item
    }

    static func appendImage(_ image: UIImage, name: String? = nil) -> Item? {
        guard let data = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else { return nil }
        let fileName = "custom_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let url = directory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return nil
        }
        let item = Item(
            id: "custom.\(Int(Date().timeIntervalSince1970 * 1000))",
            name: (name?.isEmpty == false ? name! : "自定义"),
            remoteURL: nil,
            localFileName: fileName
        )
        var items = load()
        items.insert(item, at: 0)
        save(items)
        return item
    }
}

/// Demo：弹出「相册 / 链接」添加自定义表情，并刷新面板
enum DemoEmotionAddPresenter {
    /// 持有选图代理（UIImagePickerController.delegate 为 weak）
    private static var activePickerProxy: DemoImagePickerProxy?

    static func present(
        from viewController: UIViewController,
        board: EmotionBoardView,
        onUpdated: (() -> Void)? = nil
    ) {
        let sheet = UIAlertController(title: "添加自定义表情", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "从相册选择", style: .default) { _ in
            presentPhotoPicker(from: viewController, board: board, onUpdated: onUpdated)
        })
        sheet.addAction(UIAlertAction(title: "填写图片链接", style: .default) { _ in
            presentURLAlert(from: viewController, board: board, onUpdated: onUpdated)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = viewController.view
            pop.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 1, height: 1)
        }
        viewController.present(sheet, animated: true)
    }

    private static func refresh(board: EmotionBoardView, onUpdated: (() -> Void)?) {
        board.update(groups: DemoEmotionCatalog.makeGroups())
        onUpdated?()
    }

    private static func presentURLAlert(
        from viewController: UIViewController,
        board: EmotionBoardView,
        onUpdated: (() -> Void)?
    ) {
        let alert = UIAlertController(title: "图片链接", message: "支持 gif / png / jpg", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "https://..." }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "添加", style: .default) { _ in
            let raw = alert.textFields?.first?.text ?? ""
            guard DemoCustomStickersStore.appendRemoteURL(raw) != nil else { return }
            refresh(board: board, onUpdated: onUpdated)
        })
        viewController.present(alert, animated: true)
    }

    private static func presentPhotoPicker(
        from viewController: UIViewController,
        board: EmotionBoardView,
        onUpdated: (() -> Void)?
    ) {
        // 需要完整相册读取权限（设置里会出现「所有照片」）；不要用无权限的 PHPicker「私密访问」
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    presentFullLibraryPicker(from: viewController, board: board, onUpdated: onUpdated)
                case .limited:
                    let alert = UIAlertController(
                        title: "需要访问全部照片",
                        message: "当前是「选中的照片」。请到设置中改为「所有照片」后再添加表情。",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    })
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                    viewController.present(alert, animated: true)
                case .denied, .restricted:
                    let alert = UIAlertController(
                        title: "无法访问相册",
                        message: "请在设置中允许访问照片，并选择「所有照片」。",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    })
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                    viewController.present(alert, animated: true)
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private static func presentFullLibraryPicker(
        from viewController: UIViewController,
        board: EmotionBoardView,
        onUpdated: (() -> Void)?
    ) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        let proxy = DemoImagePickerProxy(board: board, onUpdated: onUpdated) {
            activePickerProxy = nil
        }
        activePickerProxy = proxy
        picker.delegate = proxy
        viewController.present(picker, animated: true)
    }
}

private final class DemoImagePickerProxy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private weak var board: EmotionBoardView?
    private let onUpdated: (() -> Void)?
    private let onFinished: () -> Void

    init(board: EmotionBoardView, onUpdated: (() -> Void)?, onFinished: @escaping () -> Void) {
        self.board = board
        self.onUpdated = onUpdated
        self.onFinished = onFinished
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        onFinished()
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        picker.dismiss(animated: true) { [weak self] in
            defer { self?.onFinished() }
            guard let self, let image, let board = self.board else { return }
            guard DemoCustomStickersStore.appendImage(image) != nil else { return }
            board.update(groups: DemoEmotionCatalog.makeGroups())
            self.onUpdated?()
        }
    }
}
