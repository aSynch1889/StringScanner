// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StringScanner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "stringscanner-cli", targets: ["StringScannerCLI"]),
        .executable(name: "StringScanner", targets: ["StringScanner"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .executableTarget(
            name: "StringScannerCLI",
            dependencies: [
                "StringScannerCore"
            ]
        ),
        .executableTarget(
            name: "StringScanner",
            dependencies: [
                "StringScannerCore"
            ]
        ),
        .target(
            name: "StringScannerCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax")
            ]
        )
    ]
)

