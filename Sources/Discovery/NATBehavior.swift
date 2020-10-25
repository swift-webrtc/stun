//
//  NATBehavior.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/10/25.
//  Copyright © 2020 sunlubo. All rights reserved.
//

/// [Network Address Translation (NAT) Behavioral Requirements for Unicast UDP](https://tools.ietf.org/html/rfc4787)
public enum NATBehavior {
  case endpointIndependent
  case addressDependent
  case addressAndPortDependent
}

// MARK: - NATBehavior + CustomStringConvertible

extension NATBehavior: CustomStringConvertible {
  public var description: String {
    switch self {
    case .endpointIndependent:
      return "Endpoint-Independent"
    case .addressDependent:
      return "Address-Dependent"
    case .addressAndPortDependent:
      return "Address and Port-Dependent"
    }
  }
}
