// swift-tools-version:5.9
// The Swift support library of the packages lungo generates from Lean programs: LungoKit, on
// the lungo runtime (LungoRuntime, an XCFramework). Written by lungo-dist for release 1.112.74.
import PackageDescription

let package = Package(
    name: "lungo-swift",
    platforms: [.macOS("12.0"), .iOS("15.0")],
    products: [
        .library(name: "LungoKit", targets: ["LungoKit"])
    ],
    targets: [
        .binaryTarget(name: "LungoRuntime", url: "https://release.machinefabric.com/lungo-runtime/release/1.112.74/LungoRuntime-1.112.74.xcframework.zip", checksum: "cf99b259869a35bd82c15d637bbc4a1b2e9669fc27d32a0b4b8c500eb1d87a7b"),
        .target(
            name: "LungoKit",
            dependencies: ["LungoRuntime"],
            linkerSettings: [.linkedLibrary("iconv")]
        ),
        .testTarget(
            name: "LungoKitTests",
            dependencies: ["LungoKit"],
            resources: [.copy("vectors.json")]
        ),
    ]
)
