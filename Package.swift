// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "InngageSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "InngageSDK",
            targets: ["InngageSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "InngageSDK",
            dependencies: ["SDWebImageSwiftUI"]
        ),
        .testTarget(
            name: "InngageSDKTests",
            dependencies: ["InngageSDK"]
        ),
    ]
)
