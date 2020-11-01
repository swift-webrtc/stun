//
//  Error.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

public enum STUNError: Error {
  case invalidMessageHeader
  case invalidMagicCookiee
  case invalidMessageBody
  case invalidAttributeHeader
  case invalidAttributeValue
  case timeout
  case canceled
}
