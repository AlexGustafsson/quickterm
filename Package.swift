// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "QuickTerm",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "QuickTermShared", targets: ["QuickTermShared"]),
    .executable(name: "QuickTerm", targets: ["QuickTerm"]),
    .executable(name: "QuickTermBroker", targets: ["QuickTermBroker"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
  ],
  targets: [
    .target(
      name: "QuickTerm",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "QuickTermShared"
      ],
      linkerSettings: [
        .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "./SupportingFiles/QuickTerm/Info.plist"]),
      ]
    ),
    .testTarget(
      name: "QuickTermTests",
      dependencies: ["QuickTerm"]
    ),
    .target(
      name: "QuickTermBroker",
      dependencies: ["QuickTermShared"],
      linkerSettings: [
        .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "./SupportingFiles/QuickTermBroker/Info.plist"]),
      ]
    ),
    .target(
      name: "QuickTermShared"
    ),
  ]
)
