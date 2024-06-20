// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MLTranslate",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(name: "MLTranslate", targets: ["MLTranslate"]),
    ],
    targets: [
        .binaryTarget(
            name: "MLTranslate",
            url:"https://github.com/enefry/MLTranslate/releases/download/FileStorage/MLTranslate-3.2.0.xcframework.zip",
            checksum:"4917c9b858c732d61d82e159706c4e01dc0cfeff22fcfc0cf1065f65a7279fad"
        )
    ]
)
