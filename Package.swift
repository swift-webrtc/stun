// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
  name: "webrtc-stun",
  products: [
    .library(name: "STUN", targets: ["STUN"])
  ],
  dependencies: [
    .package(url: "https://github.com/swift-webrtc/webrtc-network.git", .branch("master")),
  ],
  targets: [
    .target(
      name: "STUN",
      dependencies: [.product(name: "Network", package: "webrtc-network")]
    ),
    .target(
      name: "Client",
      dependencies: ["STUN"]
    ),
    .target(
      name: "Discovery",
      dependencies: ["STUN"]
    ),
    .testTarget(
      name: "STUNTests",
      dependencies: ["STUN"]
    ),
  ]
)
