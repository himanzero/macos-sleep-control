// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SleepControl",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SleepControl", targets: ["SleepControl"])
    ],
    targets: [
        .executableTarget(
            name: "SleepControl",
            path: "Sources/SleepControl",
            exclude: [
                "Resources"
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
