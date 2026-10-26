// swift-tools-version:5.9
// The Swift support library of the packages lungo generates from Lean programs: LungoKit, on
// the lungo runtime (LungoRuntime, an XCFramework). Written by lungo-dist for release 1.117.0.
import PackageDescription

let package = Package(
    name: "lungo-swift",
    platforms: [.macOS("12.0"), .iOS("15.0")],
    products: [
        .library(name: "LungoKit", targets: ["LungoKit"])
    ],
    targets: [
        .binaryTarget(name: "LungoRuntime", url: "https://release.machinefabric.com/lungo-runtime/release/1.117.0/LungoRuntime-1.117.0.xcframework.zip", checksum: "88a07b61ba95b04f62b0d073724358d9cb01d5a7548c2c6133672d59fb20b914"),
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
