//
//  Value.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/17.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Network

extension STUNAttribute {
  public enum Value {
    case address(SocketAddress)
    case xorAddress(SocketAddress)
    case uint32(UInt32)
    case uint64(UInt64)
    case string(String)
    case errorCode(ErrorCode)
    case uint16List([UInt16])
    case flag(Bool)
    case bytes(Array<UInt8>)
    case null

    internal var size: Int {
      switch self {
      case .address(let value):
        return value.isIPv4 ? 8 : 20
      case .xorAddress(let value):
        return value.isIPv4 ? 8 : 20
      case .uint32:
        return 4
      case .uint64:
        return 8
      case .string(let value):
        return value.utf8.count
      case .errorCode(let value):
        return 4 + value.reasonPhrase.count
      case .uint16List(let value):
        return value.count * 2
      case .flag:
        return 1
      case .bytes(let value):
        return value.count
      case .null:
        return 0
      }
    }
  }
}

extension STUNAttribute.Value {
  public var address: SocketAddress? {
    switch self {
    case .address(let value):
      return value
    case .xorAddress(let value):
      return value
    default:
      return nil
    }
  }

  public var integer: Int? {
    switch self {
    case .uint32(let value):
      return Int(value)
    case .uint64(let value):
      return Int(value)
    default:
      return nil
    }
  }

  public var string: String? {
    guard case .string(let value) = self else {
      return nil
    }
    return value
  }

  public var errorCode: ErrorCode? {
    guard case .errorCode(let value) = self else {
      return nil
    }
    return value
  }

  public var uint16List: [UInt16]? {
    guard case .uint16List(let value) = self else {
      return nil
    }
    return value
  }
}
