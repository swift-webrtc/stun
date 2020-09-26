//
//  Error.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

public enum STUNError: Error {
  case invalidServer
  case timeout
  case invalidMessageHeader
  case unsupportedMessageType
  case invalidMagicCookiee
  case invalidMessageBody
  case invalidAttributeHeader
  case unsupportedAttributeType
  case invalidAttributeValue
  case invalidAddressValue
  case invalidErrorCodeValue
}
