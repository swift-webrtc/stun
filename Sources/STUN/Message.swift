//
//  Message.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Network
import Core

// [RFC5389#section-6](https://tools.ietf.org/html/rfc5389#section-6)
//
//  0                   1                   2                   3
//  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |0 0|     STUN Message Type     |         Message Length        |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                         Magic Cookie                          |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                                                               |
// |                     Transaction ID (96 bits)                  |
// |                                                               |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
public struct STUNMessage {
  internal static let headerSize = 20
  internal static let magicCookie = 0x2112A442 as UInt32

  public let type: Kind
  public internal(set) var length: UInt16
  public let magicCookie: UInt32
  public let transactionId: STUNTransactionId
  public internal(set) var attributes: Array<STUNAttribute>

  internal var raw: ByteWriter

  public init(type: Kind, transactionId: STUNTransactionId = STUNTransactionId()) {
    self.type = type
    self.length = 0
    self.magicCookie = Self.magicCookie
    self.transactionId = transactionId
    self.attributes = []
    self.raw = ByteWriter(capacity: Self.headerSize)
    self.raw.writeInteger(type.rawValue)
    self.raw.writeInteger(length)
    self.raw.writeInteger(magicCookie)
    self.raw.writeBytes(transactionId.raw)
  }

  @discardableResult
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try raw.withUnsafeBytes(body)
  }
}

// MARK: - Decode

extension STUNMessage {

  public init(bytes: Array<UInt8>) throws {
    var reader = ByteReader(bytes)
    guard
      let rawType = reader.readInteger(as: UInt16.self),
      let length = reader.readInteger(as: UInt16.self),
      let magicCookie = reader.readInteger(as: UInt32.self),
      let transactionId = reader.readBytes(count: 12)
    else {
      throw STUNError.invalidMessageHeader
    }
    guard magicCookie == STUNMessage.magicCookie else {
      throw STUNError.invalidMagicCookiee
    }
    guard reader.count == length else {
      throw STUNError.invalidMessageBody
    }

    var attributes = [STUNAttribute]()
    while reader.count > 0 {
      guard let rawType = reader.readInteger(as: UInt16.self), let length = reader.readInteger(as: UInt16.self) else {
        throw STUNError.invalidAttributeHeader
      }
      guard reader.count >= length else {
        throw STUNError.invalidAttributeValue
      }

      let attribute = STUNAttribute(type: .init(rawValue: rawType), value: reader.readBytes(count: Int(length))!)
      attributes.append(attribute)

      reader.consume(attribute.padding)
    }

    self.type = .init(rawValue: rawType)
    self.length = length
    self.magicCookie = magicCookie
    self.transactionId = .init(raw: transactionId)
    self.attributes = attributes
    self.raw = ByteWriter(bytes: bytes)
  }
}

// MARK: - Attribute Getter

extension STUNMessage {

  public func attributeValue<T>(
    for type: STUNAttribute.Kind, as: T.Type = T.self
  ) -> T? where T: STUNAttributeValueCodable {
    guard var bytes = attribute(for: type)?.value else {
      return nil
    }

    if T.self == STUNXorAddress.self {
      let xor = [0x00, 0x00, 0x21, 0x12, 0x21, 0x12, 0xA4, 0x42] + transactionId.raw
      bytes = zip(bytes, xor).map({ $0 ^ $1 })
    }
    return T(from: bytes)
  }

  public func attribute(for type: STUNAttribute.Kind) -> STUNAttribute? {
    attributes.first(where: { $0.type == type })
  }
}

// MARK: - Attribute Setter

extension STUNMessage {

  public mutating func appendAttribute(type: STUNAttribute.Kind, value: STUNAttributeValueCodable) {
    var bytes = value.bytes
    if value is STUNXorAddress {
      let xor = [0x00, 0x00, 0x21, 0x12, 0x21, 0x12, 0xA4, 0x42] + transactionId.raw
      bytes = zip(bytes, xor).map({ $0 ^ $1 })
    }
    appendAttribute(.init(type: type, value: bytes))
  }

  public mutating func appendAttribute(_ attribute: STUNAttribute) {
    // When present, the `FINGERPRINT` attribute MUST be the last attribute in the message.
    if let type = attributes.last?.type, type == .fingerprint {
      return
    }
    // With the exception of the FINGERPRINT attribute, which appears after MESSAGE-INTEGRITY, agents MUST ignore
    // all other attributes that follow MESSAGE-INTEGRITY.
    if let type = attributes.last?.type, type == .messageIntegrity && attribute.type != .fingerprint {
      return
    }

    length += 4
    length += attribute.length + UInt16(attribute.padding)
    raw.writeInteger(length, at: 2)
    raw.writeInteger(attribute.type.rawValue)
    raw.writeInteger(attribute.length)
    raw.writeBytes(attribute.value)
    raw.writeBytes(Array(repeating: 0, count: attribute.padding))

    attributes.append(attribute)
  }
}

// MARK: - Message Integrity

extension STUNMessage {

  public mutating func appendMessageIntegrity(_ credential: STUNCredential) {
    length += 4
    length += 20
    raw.writeInteger(length, at: 2)

    let hmac = HMAC(key: credential.key, hash: .sha1)
    let bytes = hmac.authenticate(raw.withUnsafeBytes(Array.init))

    length -= 4
    length -= 20
    raw.writeInteger(length, at: 2)

    appendAttribute(.init(type: .messageIntegrity, value: bytes))
  }

  /// Validates that a STUN message has a correct MESSAGE-INTEGRITY value.
  public func validateMessageIntegrity(_ credential: STUNCredential) -> Bool {
    guard let value = attribute(for: .messageIntegrity)?.value else {
      return true
    }

    var writer = raw
    if attribute(for: .fingerprint) != nil {
      writer.removeLast(8)
      writer.writeInteger(length - 8, at: 2)
    }
    writer.removeLast(24)

    let hmac = HMAC(key: credential.key, hash: .sha1).authenticate(writer.withUnsafeBytes(Array.init))
    return hmac == value
  }
}

// MARK: - Fingerprint

extension STUNMessage {

  public mutating func appendFingerprint() {
    length += 4
    length += 4
    raw.writeInteger(length, at: 2)

    let crc32 = raw.withUnsafeBytes(Array.init).crc32 ^ 0x5354554e
    let bytes = Swift.withUnsafeBytes(of: crc32.bigEndian, Array.init)

    length -= 4
    length -= 4
    raw.writeInteger(length, at: 2)

    appendAttribute(.init(type: .fingerprint, value: bytes))
  }

  public func validateFingerprint() -> Bool {
    guard let value = attribute(for: .fingerprint)?.value else {
      return true
    }

    var writer = raw
    writer.removeLast(8)
    return writer.withUnsafeBytes(Array.init).crc32 == UInt32(bigEndianBytes: value) ^ 0x5354554e
  }
}

// MARK: - STUNMessage + CustomStringConvertible

extension STUNMessage: CustomStringConvertible {
  public var description: String {
    var string = "STUNMessage(type: \(type), id: \(transactionId), attributes: ["
    for (index, attr) in attributes.enumerated() {
      var valueString: String?
      switch attr.type {
      case .mappedAddress, .responseAddress, .sourceAddress, .changedAddress, .alternateServer, .responseOrigin, .otherAddress:
        valueString = attributeValue(for: attr.type, as: SocketAddress.self)?.description
      case .xorPeerAddress, .xorRelayedAddress, .xorMappedAddress:
        valueString = attributeValue(for: attr.type, as: STUNXorAddress.self)?.address.description
      case .username, .realm, .nonce, .software:
        valueString = attributeValue(for: attr.type, as: String.self)
      case .channelNumber, .requestedTransport, .fingerprint:
        valueString = attributeValue(for: attr.type, as: UInt32.self)?.description
      case .evenPort:
        valueString = attributeValue(for: attr.type, as: UInt8.self)?.description
      case .reservationToken:
        valueString = attributeValue(for: attr.type, as: UInt64.self)?.description
      case .errorCode:
        valueString = attributeValue(for: attr.type, as: STUNErrorCode.self)?.description
      case .unknownAttributes:
        valueString = attributeValue(for: attr.type, as: [STUNAttribute.Kind].self)?.description
      default:
        valueString = attr.value.description
      }
      string.append("STUNAttribute(type: \(attr.type), value: \(valueString ?? "invalid"))")
      if index != attributes.count - 1 {
        string.append(", ")
      }
    }
    string.append("])")
    return string
  }
}

// MARK: - STUNMessage.Kind

extension STUNMessage {
  public struct Kind: RawRepresentable, Equatable {
    public var rawValue: UInt16
    /// A Boolean value indicating whether the message is an indication.
    public var isIndication: Bool {
      rawValue & 0x0110 == 0x010
    }

    public init(rawValue: UInt16) {
      self.rawValue = rawValue
    }
  }
}

extension STUNMessage.Kind {
  /// [RFC5389#section-7](https://tools.ietf.org/html/rfc5389#section-7)
  public static let bindingRequest = Self(rawValue: 0x001)
  public static let bindingIndication = Self(rawValue: 0x011)
  public static let bindingResponse = Self(rawValue: 0x101)
  public static let bindingErrorResponse = Self(rawValue: 0x111)
  /// [RFC5766#section-5](https://tools.ietf.org/html/rfc5766#section-5)
  public static let allocateRequest = Self(rawValue: 0x003)
  public static let allocateResponse = Self(rawValue: 0x0103)
  public static let allocateErrorResponse = Self(rawValue: 0x0113)
  /// [RFC5766#section-7](https://tools.ietf.org/html/rfc5766#section-7)
  public static let refreshRequest = Self(rawValue: 0x004)
  public static let refreshResponse = Self(rawValue: 0x0104)
  public static let refreshErrorResponse = Self(rawValue: 0x0114)
  /// [RFC5766#section-10](https://tools.ietf.org/html/rfc5766#section-10)
  public static let sendIndication = Self(rawValue: 0x016)
  public static let dataIndication = Self(rawValue: 0x017)
  /// [RFC5766#section-8](https://tools.ietf.org/html/rfc5766#section-8)
  public static let createPermissionRequest = Self(rawValue: 0x008)
  public static let createPermissionResponse = Self(rawValue: 0x0108)
  public static let createPermissionErrorResponse = Self(rawValue: 0x0118)
  /// [RFC5766#section-11](https://tools.ietf.org/html/rfc5766#section-11)
  public static let channelBindRequest = Self(rawValue: 0x009)
  public static let channelBindResponse = Self(rawValue: 0x0109)
  public static let channelBindErrorResponse = Self(rawValue: 0x0119)
}

// MARK: - STUNMessage.Kind + CustomStringConvertible

extension STUNMessage.Kind: CustomStringConvertible {
  public var description: String {
    switch self {
    case .bindingRequest:
      return "bindingRequest"
    case .bindingIndication:
      return "bindingIndication"
    case .bindingResponse:
      return "bindingResponse"
    case .bindingErrorResponse:
      return "bindingErrorResponse"
    case .allocateRequest:
      return "allocateRequest"
    case .allocateResponse:
      return "allocateResponse"
    case .allocateErrorResponse:
      return "allocateErrorResponse"
    case .refreshRequest:
      return "refreshRequest"
    case .refreshResponse:
      return "refreshResponse"
    case .refreshErrorResponse:
      return "refreshErrorResponse"
    case .sendIndication:
      return "sendIndication"
    case .dataIndication:
      return "dataIndication"
    case .createPermissionRequest:
      return "createPermissionRequest"
    case .createPermissionResponse:
      return "createPermissionResponse"
    case .createPermissionErrorResponse:
      return "createPermissionErrorResponse"
    case .channelBindRequest:
      return "channelBindRequest"
    case .channelBindResponse:
      return "channelBindResponse"
    case .channelBindErrorResponse:
      return "channelBindErrorResponse"
    default:
      return "Kind(rawValue: \(rawValue)"
    }
  }
}
