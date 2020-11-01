//
//  Attribute.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
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
  public let value: Array<UInt8>

  /// Since STUN aligns attributes on 32-bit boundaries, attributes whose content
  /// is not a multiple of 4 bytes are padded with 1, 2, or 3 bytes of
  /// padding so that its value contains a multiple of 4 bytes. The
  /// padding bits are ignored, and may be any value.
  internal var padding: Int {
    Int(length) % 4 != 0 ? 4 - Int(length) % 4 : 0
  }

  public init(type: Kind, value: Array<UInt8>) {
    self.type = type
    self.length = UInt16(value.count)
    self.value = value
  }
}

// MARK: - STUNAttribute.Kind

extension STUNAttribute {
  public struct Kind: RawRepresentable, Equatable {
    public var rawValue: UInt16

    public init(rawValue: UInt16) {
      self.rawValue = rawValue
    }
  }
}

// MARK: - Comprehension-required

extension STUNAttribute.Kind {
  /// [RFC5389#section-15.1](https://tools.ietf.org/html/rfc5389#section-15.1)
  public static let mappedAddress = Self(rawValue: 0x0001)
  public static let responseAddress = Self(rawValue: 0x0002)
  /// [RFC5780#section-7.2](https://tools.ietf.org/html/rfc5780#section-7.2)
  public static let changeRequest = Self(rawValue: 0x0003)
  public static let sourceAddress = Self(rawValue: 0x0004)
  public static let changedAddress = Self(rawValue: 0x0005)
  /// [RFC5389#section-15.3](https://tools.ietf.org/html/rfc5389#section-15.3)
  public static let username = Self(rawValue: 0x0006)
  /// [RFC5389#section-15.4](https://tools.ietf.org/html/rfc5389#section-15.4)
  public static let messageIntegrity = Self(rawValue: 0x0008)
  /// [RFC5389#section-15.6](https://tools.ietf.org/html/rfc5389#section-15.6)
  public static let errorCode = Self(rawValue: 0x0009)
  /// [RFC5389#section-15.9](https://tools.ietf.org/html/rfc5389#section-15.9)
  public static let unknownAttributes = Self(rawValue: 0x000A)
  /// [RFC5766#section-14.1](https://tools.ietf.org/html/rfc5766#section-14.1)
  public static let channelNumber = Self(rawValue: 0x000C)
  /// [RFC5766#section-14.2](https://tools.ietf.org/html/rfc5766#section-14.2)
  public static let lifetime = Self(rawValue: 0x000D)
  /// [RFC5766#section-14.3](https://tools.ietf.org/html/rfc5766#section-14.3)
  public static let xorPeerAddress = Self(rawValue: 0x0012)
  /// [RFC5766#section-14.4](https://tools.ietf.org/html/rfc5766#section-14.4)
  public static let data = Self(rawValue: 0x0013)
  /// [RFC5389#section-15.7](https://tools.ietf.org/html/rfc5389#section-15.7)
  public static let realm = Self(rawValue: 0x0014)
  /// [RFC5389#section-15.8](https://tools.ietf.org/html/rfc5389#section-15.8)
  public static let nonce = Self(rawValue: 0x0015)
  /// [RFC5766#section-14.5](https://tools.ietf.org/html/rfc5766#section-14.5)
  public static let xorRelayedAddress = Self(rawValue: 0x0016)
  /// [RFC6156#section-4.1.1](https://tools.ietf.org/html/rfc6156#section-4.1.1)
  public static let requestedAddressFamily = Self(rawValue: 0x0017)
  /// [RFC5766#section-14.6](https://tools.ietf.org/html/rfc5766#section-14.6)
  public static let evenPort = Self(rawValue: 0x0018)
  /// [RFC5766#section-14.7](https://tools.ietf.org/html/rfc5766#section-14.7)
  public static let requestedTransport = Self(rawValue: 0x0019)
  /// [RFC5766#section-14.8](https://tools.ietf.org/html/rfc5766#section-14.8)
  public static let dontFragment = Self(rawValue: 0x001A)
  /// [RFC5389#section-15.2](https://tools.ietf.org/html/rfc5389#section-15.2)
  public static let xorMappedAddress = Self(rawValue: 0x0020)
  /// [RFC5766#section-14.9](https://tools.ietf.org/html/rfc5766#section-14.9)
  public static let reservationToken = Self(rawValue: 0x0022)
  /// [RFC5245#section-7.1.2.1](https://tools.ietf.org/html/rfc5245#section-7.1.2.1)
  public static let priority = Self(rawValue: 0x0024)
  public static let useCandidate = Self(rawValue: 0x0025)
  /// [RFC5780#section-7.6](https://tools.ietf.org/html/rfc5780#section-7.6)
  public static let padding = Self(rawValue: 0x0026)
  /// [RFC5780#section-7.5](https://tools.ietf.org/html/rfc5780#section-7.5)
  public static let responsePort = Self(rawValue: 0x0027)
  /// [RFC6062#section-6.2.1](https://tools.ietf.org/html/rfc6062#section-6.2.1)
  public static let connectionId = Self(rawValue: 0x002A)
}

// MARK: - Comprehension-optional

extension STUNAttribute.Kind {
  /// [RFC5389#section-15.10](https://tools.ietf.org/html/rfc5389#section-15.10)
  public static let software = Self(rawValue: 0x8022)
  /// [RFC5389#section-15.11](https://tools.ietf.org/html/rfc5389#section-15.11)
  public static let alternateServer = Self(rawValue: 0x8023)
  public static let cacheTimeout = Self(rawValue: 0x8027)
  /// [RFC5389#section-15.5](https://tools.ietf.org/html/rfc5389#section-15.5)
  public static let fingerprint = Self(rawValue: 0x8028)
  /// [RFC5245#section-7.1.2.2](https://tools.ietf.org/html/rfc5245#section-7.1.2.2)
  public static let iceControlled = Self(rawValue: 0x8029)
  public static let iceControlling = Self(rawValue: 0x802A)
  /// [RFC5780#section-7.3](https://tools.ietf.org/html/rfc5780#section-7.3)
  public static let responseOrigin = Self(rawValue: 0x802B)
  /// [RFC5780#section-7.4](https://tools.ietf.org/html/rfc5780#section-7.4)
  public static let otherAddress = Self(rawValue: 0x802C)
}

// MARK: - STUNAttribute.Kind + CustomStringConvertible

extension STUNAttribute.Kind: CustomStringConvertible {
  public var description: String {
    switch self {
    case .mappedAddress:
      return "MAPPED-ADDRESS"
    case .responseAddress:
      return "RESPONSE-ADDRESS"
    case .changeRequest:
      return "CHANGE-REQUEST"
    case .sourceAddress:
      return "SOURCE-ADDRESS"
    case .changedAddress:
      return "CHANGED-ADDRESS"
    case .username:
      return "USERNAME"
    case .messageIntegrity:
      return "MESSAGE-INTEGRITY"
    case .errorCode:
      return "ERROR-CODE"
    case .unknownAttributes:
      return "UNKNOWN-ATTRIBUTES"
    case .channelNumber:
      return "CHANNEL-NUMBER"
    case .lifetime:
      return "LIFETIME"
    case .xorPeerAddress:
      return "XOR-PEER-ADDRESS"
    case .data:
      return "DATA"
    case .realm:
      return "REALM"
    case .nonce:
      return "NONCE"
    case .xorRelayedAddress:
      return "XOR-RELAYED-ADDRESS"
    case .requestedAddressFamily:
      return "REQUESTED-ADDRESS-FAMILY"
    case .evenPort:
      return "EVEN-PORT"
    case .requestedTransport:
      return "REQUESTED-TRANSPORT"
    case .dontFragment:
      return "DONT-FRAGMENT"
    case .xorMappedAddress:
      return "XOR-MAPPED-ADDRESS"
    case .reservationToken:
      return "RESERVATION-TOKEN"
    case .priority:
      return "PRIORITY"
    case .useCandidate:
      return "USE-CANDIDATE"
    case .padding:
      return "PADDING"
    case .responsePort:
      return "RESPONSE-PORT"
    case .connectionId:
      return "CONNECTION-ID"
    case .software:
      return "SOFTWARE"
    case .alternateServer:
      return "ALTERNATE-SERVER"
    case .cacheTimeout:
      return "CACHE-TIMEOUT"
    case .fingerprint:
      return "FINGERPRINT"
    case .iceControlled:
      return "ICE-CONTROLLED"
    case .iceControlling:
      return "ICE-CONTROLLING"
    case .responseOrigin:
      return "RESPONSE-ORIGIN"
    case .otherAddress:
      return "OTHER-ADDRESS"
    default:
      return "Type(rawValue: \(rawValue))"
    }
  }
}

// MARK: - STUNAttribute.Kind + STUNAttributeValueCodable

extension Array: STUNAttributeValueCodable where Element == STUNAttribute.Kind {
  public var bytes: Array<UInt8> {
    map(\.rawValue.bigEndian).withUnsafeBytes(Array<UInt8>.init)
  }

  public init?(from bytes: Array<UInt8>) {
    self = bytes.withUnsafeBytes {
      Array($0.bindMemory(to: UInt16.self).map(\.bigEndian).map(Element.init(rawValue:)))
    }
  }
}
