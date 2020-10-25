//
//  main.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/10/21.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN
import Core
import Logging
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

// https://www.voip-info.org/stun/
func main() throws {
  let discovery = try NATBehaviorDiscovery(server: "stun:stun.stunprotocol.org:3478")
  discovery.discoverNATMappingBehavior { result in
    switch result {
    case .success(let behavior):
      print("Detected NAT mapping behavior: \(behavior) - ", terminator: "")
      switch behavior {
      case .endpointIndependent:
        print("Host's NAT uses same public IP address regardless of destination address. STUN is usable.")
      case .addressDependent:
        print("Host's NAT uses different public IP address for different destination address. STUN is not usable.")
      case .addressAndPortDependent:
        print("Host's NAT uses different public IP address for different destination address and port. STUN is not usable.")
      }
    case .failure(let error):
      print("Detected NAT mapping behavior failed: \(error)")
    }

    discovery.discoverNATFilteringBehavior { result in
      switch result {
      case .success(let behavior):
        print("Detected NAT filtering behavior: \(behavior) - ", terminator: "")
        switch behavior {
        case .endpointIndependent:
          print("Host's NAT allows to receive UDP packet from any external address. STUN is usable.")
        case .addressDependent:
          print("Host's NAT allows to receive UDP packet from external address that host had previously sent data to. STUN is usable.")
        case .addressAndPortDependent:
          print("Host's NAT allows to receive UDP packet from external address and port that host had previously sent data to. STUN is usable.")
        }
      case .failure(let error):
        print("Detected NAT filtering behavior failed: \(error)")
      }
    }
  }
  sleep(180)
}

do {
  logger.logLevel = .trace
  try main()
} catch {
  print(error)
}
