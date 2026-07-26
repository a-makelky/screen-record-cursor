// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScreenRecordCursor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ScreenRecordCursor",
            targets: ["ScreenRecordCursor"]
        )
    ],
    targets: [
        .target(
            name: "CursorCore"
        ),
        .executableTarget(
            name: "ScreenRecordCursor",
            dependencies: ["CursorCore"]
        ),
        .testTarget(
            name: "CursorCoreTests",
            dependencies: ["CursorCore"]
        )
    ]
)
