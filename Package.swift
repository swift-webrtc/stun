// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
  name: "webrtc-stun",
  products: [
    .library(name: "STUN", targets: ["STUN"])
  ],
  dependencies: [
    .package(name: "webrtc-asyncio", url: "https://github.com/swift-webrtc/asyncio.git", .branch("main"))
  ],
  targets: [
    .target(name: "STUN", dependencies: [.product(name: "AsyncIO", package: "webrtc-asyncio")]),
    .target(name: "Client", dependencies: ["STUN"]),
    .target(name: "Discovery", dependencies: ["STUN"]),
    .testTarget(name: "STUNTests", dependencies: ["STUN"]),
  ]
)
