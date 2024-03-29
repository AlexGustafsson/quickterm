// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "QuickTerm",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "QuickTermShared", targets: ["QuickTermShared"]),
    .executable(name: "QuickTerm", targets: ["QuickTerm"]),
    .library(name: "QuickTermLibrary", targets: ["QuickTermLibrary"]),
    .executable(name: "QuickTermBroker", targets: ["QuickTermBroker"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.3")),
    .package(url: "https://github.com/soffes/HotKey", from: "0.1.3"),
    .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
  ],
  targets: [
    .target(
      name: "QuickTerm",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "HotKey", package: "HotKey"),
        .product(name: "Yams", package: "Yams"),
        "QuickTermShared",
        "QuickTermLibrary",
      ],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker",
          "./SupportingFiles/QuickTerm/Info.plist",
        ]),
      ]
    ),
    .target(
      name: "QuickTermLibrary",
      dependencies: [
        "QuickTermShared",
      ]
    ),
    .testTarget(
      name: "QuickTermLibraryTests",
      dependencies: ["QuickTermLibrary"]
    ),
    .target(
      name: "QuickTermBroker",
      dependencies: ["QuickTermShared"],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker",
          "./SupportingFiles/QuickTermBroker/Info.plist",
        ]),
      ]
    ),
    .target(
      name: "QuickTermShared"
    ),
  ]
)
