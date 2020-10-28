//
//  ErrorCode.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Core

/// [RFC5389#section-15.6](https://tools.ietf.org/html/rfc5389#section-15.6)
public struct STUNErrorCode {
  // [RFC5389#section-15.6](https://tools.ietf.org/html/rfc5389#section-15.6)
  public static let tryAlternate = Self(code: 300, reasonPhrase: "Try Alternate")
  public static let badRequest = Self(code: 400, reasonPhrase: "Bad Request")
  public static let unauthorized = Self(code: 401, reasonPhrase: "Unauthorized")
  public static let unknownAttribute = Self(code: 420, reasonPhrase: "Unknown Attribute")
  public static let staleNonce = Self(code: 438, reasonPhrase: "Stale Nonce")
  public static let roleConflict = Self(code: 487, reasonPhrase: "Role Conflict")
  public static let serverError = Self(code: 500, reasonPhrase: "Server Error")
  // [RFC5766#section-15](https://tools.ietf.org/html/rfc5766#section-15)
  public static let forbidden = Self(code: 403, reasonPhrase: "Forbidden")
  public static let allocationMismatch = Self(code: 437, reasonPhrase: "Allocation Mismatch")
  public static let wrongCredentials = Self(code: 441, reasonPhrase: "Wrong Credentials")
  public static let unsupportedTransportProtocol = Self(code: 442, reasonPhrase: "Unsupported Transport Protocol")
  public static let allocationQuotaReached = Self(code: 486, reasonPhrase: "Allocation Quota Reached")
  public static let insufficientCapacity = Self(code: 508, reasonPhrase: "Insufficient Capacity")
  // [RFC6062#section-6.3](https://tools.ietf.org/html/rfc6062#section-6.3)
  public static let connectionAlreadyExists = Self(code: 446, reasonPhrase: "Connection Already Exists")
  public static let connectionTimeoutOrFailure = Self(code: 447, reasonPhrase: "Connection Timeout or Failure")
  // [RFC6156#section-10.2](https://tools.ietf.org/html/rfc6156#section-10.2)
  public static let addressFamilyNotSupported = Self(code: 440, reasonPhrase: "Address Family not Supported")
  public static let peerAddressFamilyMismatch = Self(code: 443, reasonPhrase: "Peer Address Family Mismatch")

  public let code: UInt16
  public let reasonPhrase: String

  internal init(code: UInt16, reasonPhrase: String) {
    self.code = code
    self.reasonPhrase = reasonPhrase
  }
}

// MARK: - STUNErrorCode + Equatable

extension STUNErrorCode: Equatable {

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.code == rhs.code
  }
}

// MARK: - STUNErrorCode + CustomStringConvertible

extension STUNErrorCode: CustomStringConvertible {
  public var description: String {
    "STUNErrorCode(code: \(code), reasonPhrase:\(reasonPhrase))"
  }
}

// MARK: - STUNErrorCode + STUNAttributeValueCodable

extension STUNErrorCode: STUNAttributeValueCodable {

  public var bytes: Array<UInt8> {
    var writer = ByteWriter()
    writer.writeInteger(0, as: UInt16.self)
    writer.writeInteger(UInt8(code / 100))
    writer.writeInteger(UInt8(code % 100))
    writer.writeString(reasonPhrase)
    return writer.withUnsafeBytes(Array.init)
  }

  public init?(from bytes: Array<UInt8>) {
    var reader = ByteReader(bytes.dropFirst(2))
    guard
      let c = reader.readInteger(as: UInt8.self),
      let n = reader.readInteger(as: UInt8.self),
      let r = reader.readString(count: reader.count)
    else {
      return nil
    }
    self = Self(code: UInt16(c) * 100 + UInt16(n), reasonPhrase: r)
  }
}
