// swift-tools-version:5.9
// The Swift support library of the packages lungo generates from Lean programs: LungoKit, on
// the lungo runtime (LungoRuntime, an XCFramework). Written by lungo-dist for release 1.88.0.
import PackageDescription

let package = Package(
    name: "lungo-swift",
    platforms: [.macOS("12.0"), .iOS("15.0")],
    products: [
        .library(name: "LungoKit", targets: ["LungoKit"])
    ],
    targets: [
        .binaryTarget(name: "LungoRuntime", url: "https://release-staging.machinefabric.com/lungo-runtime/release/1.88.0/LungoRuntime-1.88.0.xcframework.zip", checksum: "3f7fb8ae58b2e385305afc054d84b270f9459e2e1b2d2cf879625088a6cb5013"),
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
