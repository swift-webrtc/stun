//
//  Credential.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/15.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Core

/// [RFC5389#section-15.4](https://tools.ietf.org/html/rfc5389#section-15.4)
public enum STUNCredential {
  case short(password: String)
  case long(username: String, password: String, realm: String)

  public var key: Array<UInt8> {
    switch self {
    case .short(let password):
      return password.bytes
    case .long(let username, let password, let realm):
      return "\(username):\(realm):\(password)".md5
    }
  }
}
