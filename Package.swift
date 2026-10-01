// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QuickMailSender",
    defaultLocalization: "en",
    platforms: [.iOS(.v16),.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "QuickMailSender",
            targets: ["QuickMailSender"]),
    ],
    dependencies: [.package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "QuickMailSender",
            dependencies: [.product(name: "Zip", package: "Zip")],
            resources: [.process("Localizable.xcstrings")]),
        .testTarget(
            name: "QuickMailSenderTests",
            dependencies: ["QuickMailSender", .product(name: "Zip", package: "Zip")]
        ),
    ]
)
