// swift-tools-version:5.9
// The Swift support library of the packages lungo generates from Lean programs: LungoKit, on
// the lungo runtime (LungoRuntime, an XCFramework). Written by lungo-dist for release 1.127.0.
import PackageDescription

let package = Package(
    name: "lungo-swift",
    platforms: [.macOS("12.0"), .iOS("15.0")],
    products: [
        .library(name: "LungoKit", targets: ["LungoKit"])
    ],
    targets: [
        .binaryTarget(name: "LungoRuntime", url: "https://release.machinefabric.com/lungo-runtime/release/1.127.0/LungoRuntime-1.127.0.xcframework.zip", checksum: "6c4f2ac7f674851d583f11df2cb2d5c16ef7090554ec18897f64dba44426e14e"),
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
