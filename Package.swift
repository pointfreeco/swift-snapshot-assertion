// swift-tools-version:5.0
import Foundation
import PackageDescription

let package = Package(
  name: "SnapshotTesting",
  platforms: [
    .iOS(.v10),
    .macOS(.v10_10),
    .tvOS(.v10)
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  targets: [
    .target(
      name: "SnapshotTesting",
      dependencies: []),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: ["SnapshotTesting"]),
  ]
)

if ProcessInfo.processInfo.environment.keys.contains("PF_DEVELOP") {
  package.dependencies.append(
    contentsOf: [
      .package(url: "https://github.com/yonaskolb/XcodeGen.git", .exact("2.13.1")),
    ]
  )
}
