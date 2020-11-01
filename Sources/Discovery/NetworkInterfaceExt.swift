//
//  NetworkInterfaceExt.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/10/29.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO

extension NetworkInterface {
  internal static var localAddress: SocketAddress? {
    NetworkInterface.all.first(where: { !$0.address.ip.isLoopback && $0.address.isIPv4 })?.address
  }
}
