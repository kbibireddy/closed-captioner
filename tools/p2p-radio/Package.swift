// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "p2p-radio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "p2p-radio", targets: ["RadioPeer"])
    ],
    targets: [
        .executableTarget(
            name: "RadioPeer",
            path: "Sources/RadioPeer"
        )
    ]
)
