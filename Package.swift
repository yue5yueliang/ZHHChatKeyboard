// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ZHHChatKeyboard",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ZHHChatKeyboard", targets: ["ZHHChatKeyboard"])
    ],
    targets: [
        .target(
            name: "ZHHChatKeyboard",
            path: "ZHHChatKeyboard",
            sources: ["Classes"],
            resources: [
                .process("Assets"),
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "ZHHChatKeyboardTests",
            dependencies: ["ZHHChatKeyboard"],
            path: "Tests"
        )
    ]
)
