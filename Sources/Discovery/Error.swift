//
//  Error.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/10/25.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN

public enum NATBehaviorDiscoveryError: Error {
  case invalidLocalAddress
  case invalidServer
  case attributeNotFound(STUNAttribute.Kind)
  case noUDPConnectivity
}
