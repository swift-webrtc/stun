//
//  main.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/10/21.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN
import AsyncIO
import Core
import Logging

let logger: Logger = {
  var l = Logger(label: "swift-webrtc.NATBehaviorDiscovery")
  l.logLevel = .trace
  return l
}()

// https://www.voip-info.org/stun/
func main() throws {
  let discovery = NATBehaviorDiscovery(server: SocketAddress("stun.stunprotocol.org:3478")!)
  discovery.discover { result in
    switch result {
    case .success((let mappingBehavior, let filteringBehavior)):
      print("Detected NAT mapping behavior: \(mappingBehavior) - ", terminator: "")
      switch mappingBehavior {
      case .endpointIndependent:
        print("Host's NAT uses same public IP address regardless of destination address. STUN is usable.")
      case .addressDependent:
        print("Host's NAT uses different public IP address for different destination address. STUN is not usable.")
      case .addressAndPortDependent:
        print("Host's NAT uses different public IP address for different destination address and port. STUN is not usable.")
      }

      print("Detected NAT filtering behavior: \(filteringBehavior) - ", terminator: "")
      switch filteringBehavior {
      case .endpointIndependent:
        print("Host's NAT allows to receive UDP packet from any external address. STUN is usable.")
      case .addressDependent:
        print("Host's NAT allows to receive UDP packet from external address that host had previously sent data to. STUN is usable.")
      case .addressAndPortDependent:
        print("Host's NAT allows to receive UDP packet from external address and port that host had previously sent data to. STUN is usable.")
      }
    case .failure(let error):
      print("Detected failed: \(error)")
    }
  }

  try EventLoop.default.run()
  try EventLoop.default.close()
}

do {
  LoggerConfiguration.default.logLevel = .trace
  try main()
} catch {
  print(error)
}
