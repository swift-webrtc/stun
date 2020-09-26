//
//  Attribute.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Network
import Core

// [RFC5389#section-15](https://tools.ietf.org/html/rfc5389#section-15)
//
//  0                   1                   2                   3
//  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |         Type                  |            Length             |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                         Value (variable)                ....
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
public struct STUNAttribute {
  public let type: Kind
  public let length: UInt16
  public let value: Value

  /// Since STUN aligns attributes on 32-bit boundaries, attributes whose content
  /// is not a multiple of 4 bytes are padded with 1, 2, or 3 bytes of
  /// padding so that its value contains a multiple of 4 bytes. The
  /// padding bits are ignored, and may be any value.
  internal var padding: Int {
    Int(length) % 4 != 0 ? 4 - Int(length) % 4 : 0
  }

  internal init(type: Kind, length: UInt16, value: Value) {
    self.type = type
    self.length = length
    self.value = value
  }

  public init(type: Kind, value: Value) {
    self.type = type
    self.length = UInt16(value.size)
    self.value = value
  }
}

extension STUNAttribute {

  public static func unknownAttributes(_ value: [Kind]) -> Self {
    Self(type: .unknownAttributes, value: .uint16List(value.map(\.rawValue)))
  }

  public static func messageIntegrity(_ credential: STUNCredential) -> Self {
    Self(type: .messageIntegrity, length: 20, value: .bytes(credential.key))
  }

  public static func fingerprint() -> Self {
    Self(type: .fingerprint, value: .uint32(0))
  }
}

// MARK: - STUNAttribute.Kind

extension STUNAttribute {
  public enum Kind: UInt16 {
    /// [RFC5389#section-15.1](https://tools.ietf.org/html/rfc5389#section-15.1)
    case mappedAddress = 0x0001
    /// [RFC5389#section-15.3](https://tools.ietf.org/html/rfc5389#section-15.3)
    case username = 0x0006
    /// [RFC5389#section-15.4](https://tools.ietf.org/html/rfc5389#section-15.4)
    case messageIntegrity = 0x0008
    /// [RFC5389#section-15.6](https://tools.ietf.org/html/rfc5389#section-15.6)
    case errorCode = 0x0009
    /// [RFC5389#section-15.9](https://tools.ietf.org/html/rfc5389#section-15.9)
    case unknownAttributes = 0x000A
    /// [RFC5389#section-15.7](https://tools.ietf.org/html/rfc5389#section-15.7)
    case realm = 0x0014
    /// [RFC5389#section-15.8](https://tools.ietf.org/html/rfc5389#section-15.8)
    case nonce = 0x0015
    /// [RFC5389#section-15.2](https://tools.ietf.org/html/rfc5389#section-15.2)
    case xorMappedAddress = 0x0020
    /// [RFC5389#section-15.10](https://tools.ietf.org/html/rfc5389#section-15.10)
    case software = 0x8022
    /// [RFC5389#section-15.11](https://tools.ietf.org/html/rfc5389#section-15.11)
    case alternateServer = 0x8023
    /// [RFC5389#section-15.5](https://tools.ietf.org/html/rfc5389#section-15.5)
    case fingerprint = 0x8028
    /// [RFC5245#section-7.1.2.1](https://tools.ietf.org/html/rfc5245#section-7.1.2.1)
    case priority = 0x0024
    case useCandidate = 0x0025
    /// [RFC5245#section-7.1.2.2](https://tools.ietf.org/html/rfc5245#section-7.1.2.2)
    case iceControlled = 0x8029
    case iceControlling = 0x802A
    /// [RFC5766#section-14.1](https://tools.ietf.org/html/rfc5766#section-14.1)
    case channelNumber = 0x000C
    /// [RFC5766#section-14.2](https://tools.ietf.org/html/rfc5766#section-14.2)
    case lifetime = 0x000D
    /// [RFC5766#section-14.3](https://tools.ietf.org/html/rfc5766#section-14.3)
    case xorPeerAddress = 0x0012
    /// [RFC5766#section-14.4](https://tools.ietf.org/html/rfc5766#section-14.4)
    case data = 0x0013
    /// [RFC5766#section-14.5](https://tools.ietf.org/html/rfc5766#section-14.5)
    case xorRelayedAddress = 0x0016
    /// [RFC5766#section-14.6](https://tools.ietf.org/html/rfc5766#section-14.6)
    case evenPort = 0x0018
    /// [RFC5766#section-14.7](https://tools.ietf.org/html/rfc5766#section-14.7)
    case requestedTransport = 0x0019
    /// [RFC5766#section-14.8](https://tools.ietf.org/html/rfc5766#section-14.8)
    case dontFragment = 0x001A
    /// [RFC5766#section-14.9](https://tools.ietf.org/html/rfc5766#section-14.9)
    case reservationToken = 0x0022
    /// [RFC5780#section-7.2](https://tools.ietf.org/html/rfc5780#section-7.2)
    case changeRequest = 0x0003
    /// [RFC5780#section-7.5](https://tools.ietf.org/html/rfc5780#section-7.5)
    case responsePort = 0x0027
    /// [RFC5780#section-7.6](https://tools.ietf.org/html/rfc5780#section-7.6)
    case padding = 0x0026
    case cacheTimeout = 0x8027
    /// [RFC5780#section-7.3](https://tools.ietf.org/html/rfc5780#section-7.3)
    case responseOrigin = 0x802b
    /// [RFC5780#section-7.4](https://tools.ietf.org/html/rfc5780#section-7.4)
    case otherAddress = 0x802c
    /// [RFC6062#section-6.2.1](https://tools.ietf.org/html/rfc6062#section-6.2.1)
    case connectionId = 0x002a
    /// [RFC6156#section-4.1.1](https://tools.ietf.org/html/rfc6156#section-4.1.1)
    case requestedAddressFamily = 0x0017
  }
}

// MARK: - STUNAttribute.Kind + CustomStringConvertible

extension STUNAttribute.Kind: CustomStringConvertible {
  public var description: String {
    switch self {
    case .mappedAddress:
      return "MAPPED-ADDRESS"
    case .username:
      return "USERNAME"
    case .messageIntegrity:
      return "MESSAGE-INTEGRITY"
    case .errorCode:
      return "ERROR-CODE"
    case .unknownAttributes:
      return "UNKNOWN-ATTRIBUTES"
    case .realm:
      return "REALM"
    case .nonce:
      return "NONCE"
    case .xorMappedAddress:
      return "XOR-MAPPED-ADDRESS"
    case .software:
      return "SOFTWARE"
    case .alternateServer:
      return "ALTERNATE-SERVER"
    case .fingerprint:
      return "FINGERPRINT"
    case .priority:
      return "PRIORITY"
    case .useCandidate:
      return "USE-CANDIDATE"
    case .iceControlled:
      return "ICE-CONTROLLED"
    case .iceControlling:
      return "ICE-CONTROLLING"
    case .channelNumber:
      return "CHANNEL-NUMBER"
    case .lifetime:
      return "LIFETIME"
    case .xorPeerAddress:
      return "XOR-PEER-ADDRESS"
    case .data:
      return "DATA"
    case .xorRelayedAddress:
      return "XOR-RELAYED-ADDRESS"
    case .evenPort:
      return "EVEN-PORT"
    case .requestedTransport:
      return "REQUESTED-TRANSPORT"
    case .dontFragment:
      return "DONT-FRAGMENT"
    case .reservationToken:
      return "RESERVATION-TOKEN"
    case .changeRequest:
      return "CHANGE-REQUEST"
    case .responsePort:
      return "RESPONSE-PORT"
    case .padding:
      return "PADDING"
    case .cacheTimeout:
      return "CACHE-TIMEOUT"
    case .responseOrigin:
      return "RESPONSE-ORIGIN"
    case .otherAddress:
      return "OTHER-ADDRESS"
    case .connectionId:
      return "CONNECTION-ID"
    case .requestedAddressFamily:
      return "REQUESTED-ADDRESS-FAMILY"
    }
  }
}
