# lungo-swift

The Swift support library of [lungo](https://github.com/machinefabric/lungo) (`LungoKit`):
the wire format and the calls into lungo's runtime that the Swift packages lungo generates
build on. A generated package depends on it; you do not use it directly.

```swift
.package(url: "https://github.com/machinefabric/lungo-swift.git", exact: "<lungo version>")
```

Each release is tagged on the `dist` branch, whose `Package.swift` names the release's prebuilt
runtime (an XCFramework); `main` holds the source, with `Package.swift.in`. A generated package
requires exactly the release of lungo that generated it. Documentation:
<https://lungo.machinefabric.com/docs>.

Licensed under the [Apache License, Version 2.0](LICENSE).
