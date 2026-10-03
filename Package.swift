// swift-tools-version:5.9
// The Swift support library of the packages lungo generates from Lean programs: LungoKit, on
// the lungo runtime (LungoRuntime, an XCFramework). Written by lungo-dist for release 1.82.64.
import PackageDescription

let package = Package(
    name: "lungo-swift",
    platforms: [.macOS("12.0"), .iOS("15.0")],
    products: [
        .library(name: "LungoKit", targets: ["LungoKit"])
    ],
    targets: [
        .binaryTarget(name: "LungoRuntime", url: "https://release-staging.machinefabric.com/lungo-runtime/release/1.82.64/LungoRuntime-1.82.64.xcframework.zip", checksum: "78e40b1b2db8989414ded04c97c095ffa0cc3835c7864df155f6f017b852a657"),
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
