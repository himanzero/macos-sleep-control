// swift-tools-version: 5.10
import Foundation
import PackageDescription

let testingPluginPath: String = {
    var candidatePaths: [String] = []
    if let devDir = ProcessInfo.processInfo.environment["DEVELOPER_DIR"], !devDir.isEmpty {
        candidatePaths.append("\(devDir)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing")
        candidatePaths.append("\(devDir)/usr/lib/swift/host/plugins/testing")
    }
    candidatePaths.append(contentsOf: [
        "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing",
        "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing",
        "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing"
    ])
    for path in candidatePaths {
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
    }
    return candidatePaths.first ?? "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"
}()

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
        ),
        .testTarget(
            name: "SleepControlTests",
            dependencies: ["SleepControl"],
            path: "Tests/SleepControlTests",
            swiftSettings: [
                .unsafeFlags([
                    "-plugin-path",
                    testingPluginPath
                ])
            ]
        )
    ]
)
