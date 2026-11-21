//
//  DemoEmotionGIFLoader.swift
//  ZHHChatKeyboard_Example
//
//  Created by 桃色三岁 on 2026/11/18.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import ImageIO
import UIKit
import ZHHChatKeyboard

/// Demo：按 `Emotion.identifier` 拉取远程 GIF（仅 Example，不可商用）
final class DemoEmotionGIFLoader: EmotionImageLoading {

    static let shared = DemoEmotionGIFLoader()

    /// identifier → 远程 GIF URL
    private var urlByIdentifier: [String: URL] = [:]
    private var memoryCache: [String: UIImage] = [:]
    private var failedIdentifiers: Set<String> = []
    private var inflightIdentifiers: Set<String> = []
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()

    private init() {}

    /// 注册自定义包里的远程地址
    func register(urlByIdentifier: [String: URL]) {
        self.urlByIdentifier.merge(urlByIdentifier) { _, new in new }
    }

    func emotionBoardView(_ boardView: EmotionBoardView, loadImageFor emotion: Emotion, completion: @escaping (UIImage?) -> Void) {
        let id = emotion.identifier
        if let cached = memoryCache[id] {
            completion(cached)
            return
        }
        if failedIdentifiers.contains(id) || inflightIdentifiers.contains(id) {
            completion(nil)
            return
        }
        guard let rawURL = urlByIdentifier[id] else {
            completion(nil)
            return
        }
        let url = Self.preferHTTPS(rawURL)
        inflightIdentifiers.insert(id)
        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            let image = data.flatMap(Self.makeImage(from:))
            DispatchQueue.main.async {
                self.inflightIdentifiers.remove(id)
                if let image {
                    self.memoryCache[id] = image
                } else {
                    // 失败记下来，避免 cell 反复请求把控制台刷爆（如 ATS 拦 http）
                    self.failedIdentifiers.insert(id)
                }
                completion(image)
            }
        }.resume()
    }

    /// ATS 默认禁止明文 http，Demo 优先改成 https
    private static func preferHTTPS(_ url: URL) -> URL {
        guard url.scheme?.lowercased() == "http" else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.url ?? url
    }

    /// GIF 多帧则做成动画 `UIImage`，否则静态图
    private static func makeImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return UIImage(data: data) }

        var frames: [UIImage] = []
        var duration: Double = 0
        frames.reserveCapacity(count)
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? 0.1
            duration += max(delay, 0.02)
        }
        guard !frames.isEmpty else { return UIImage(data: data) }
        return UIImage.animatedImage(with: frames, duration: max(duration, 0.1))
    }
}
