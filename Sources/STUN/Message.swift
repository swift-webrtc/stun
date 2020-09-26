//
//  Message.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

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
  internal static let magicCookie: UInt32 = 0x2112A442

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
    self.raw = ByteWriter(capacity: 20)
    self.raw.writeInteger(type.rawValue)
    self.raw.writeInteger(length)
    self.raw.writeInteger(magicCookie)
    self.raw.writeBytes(transactionId.raw)
  }

  public mutating func append(_ attribute: STUNAttribute) {
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

    var bytes: Array<UInt8>
    switch attribute.value {
    case .address(let value):
      bytes = value.bytes
    case .xorAddress(let value):
      let xor = [0x00, 0x00, 0x21, 0x12, 0x21, 0x12, 0xA4, 0x42] + transactionId.raw
      bytes = zip(value.bytes, xor).map({ $0 ^ $1 })
    case .uint32 where attribute.type == .fingerprint:
      var crc32 = raw.withUnsafeBytes(Array.init).crc32
      crc32 = (crc32 ^ 0x5354554e).bigEndian
      bytes = withUnsafeMutableBytes(of: &crc32, Array.init)
    case .uint32(let value):
      bytes = Swift.withUnsafeBytes(of: value, Array.init)
    case .uint64(let value):
      bytes = Swift.withUnsafeBytes(of: value, Array.init)
    case .string(let value):
      bytes = value.bytes
    case .errorCode(let value):
      bytes = value.bytes
    case .uint16List(let value):
      bytes = value.withUnsafeBytes(Array.init)
    case .flag(let value):
      bytes = [value ? 1 : 0]
    case .bytes(let value) where attribute.type == .messageIntegrity:
      let hmac = HMAC(key: value, hash: .sha1)
      bytes = hmac.authenticate(raw.withUnsafeBytes(Array.init))
    case .bytes(let value):
      bytes = value
    case .null:
      bytes = []
    }
    raw.writeInteger(attribute.type.rawValue)
    raw.writeInteger(attribute.length)
    raw.writeBytes(bytes)
    raw.writeBytes(Array(repeating: 0, count: attribute.padding))

    attributes.append(attribute)
  }

  public func attribute(for type: STUNAttribute.Kind) -> STUNAttribute? {
    attributes.first(where: { $0.type == type })
  }

  @discardableResult
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try raw.withUnsafeBytes(body)
  }
}

extension STUNMessage {

  public func contains(_ type: STUNAttribute.Kind) -> Bool {
    attributes.contains(where: { $0.type == type })
  }

  public func forEach(_ body: (STUNAttribute) throws -> Void) rethrows {
    try attributes.forEach(body)
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
    guard let type = STUNMessage.Kind(rawValue: rawType) else {
      throw STUNError.unsupportedMessageType
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
      guard let type = STUNAttribute.Kind(rawValue: rawType) else {
        throw STUNError.unsupportedAttributeType
      }
      guard reader.count >= length else {
        throw STUNError.invalidAttributeValue
      }

      let value: STUNAttribute.Value
      switch type {
      case .mappedAddress, .alternateServer:
        value = .address(try .init(bytes: reader.readBytes(count: Int(length))!))
      case .xorMappedAddress, .xorPeerAddress, .xorRelayedAddress:
        value = .xorAddress(try .init(bytes: reader.readBytes(count: Int(length))!, transactionId: .init(raw: transactionId)))
      case .username, .software, .realm, .nonce:
        value = .string(String(decoding: reader.readBytes(count: Int(length))!, as: UTF8.self))
      case .channelNumber, .requestedTransport:
        value = .uint32(reader.readInteger(endianness: .little)!)
      case .evenPort:
        value = .flag(reader.readInteger(as: UInt8.self) == 1)
      case .reservationToken:
        value = .uint64(reader.readInteger()!)
      case .errorCode:
        value = .errorCode(try .init(bytes: reader.readBytes(count: Int(length))!))
      case .unknownAttributes:
        value = .uint16List(
          reader.readBytes(count: Int(length))!.withUnsafeBytes {
            Array($0.bindMemory(to: UInt16.self))
          }
        )
      case .fingerprint:
        value = .uint32(reader.readInteger()!)
      default:
        value = .bytes(reader.readBytes(count: Int(length))!)
      }

      let attribute = STUNAttribute(type: type, value: value)
      attributes.append(attribute)

      reader.consume(attribute.padding)
    }

    self.type = type
    self.length = length
    self.magicCookie = magicCookie
    self.transactionId = .init(raw: transactionId)
    self.attributes = attributes
    self.raw = ByteWriter(bytes: bytes)
  }
}

extension STUNMessage {

  /// Validates that a STUN message has a correct MESSAGE-INTEGRITY value.
  public func validateMessageIntegrity(_ credential: STUNCredential) -> Bool {
    guard case .bytes(let value) = attribute(for: .messageIntegrity)?.value else {
      return false
    }

    var writer = raw
    if contains(.fingerprint) {
      writer.removeLast(8)
      writer.writeInteger(length - 8, at: 2)
    }
    writer.removeLast(24)

    let hmac = HMAC(key: credential.key, hash: .sha1).authenticate(writer.withUnsafeBytes(Array.init))
    return hmac == value
  }

  public func validateFingerprint() -> Bool {
    guard case .uint32(let value) = attribute(for: .fingerprint)?.value else {
      return false
    }

    var writer = raw
    writer.removeLast(8)
    return writer.withUnsafeBytes(Array.init).crc32 == value ^ 0x5354554e
  }
}

// MARK: - STUNMessage.Kind

extension STUNMessage {
  public enum Kind: UInt16 {
    /// [RFC5389#section-7](https://tools.ietf.org/html/rfc5389#section-7)
    case bindingRequest = 0x001
    case bindingIndication = 0x011
    case bindingResponse = 0x101
    case bindingErrorResponse = 0x111
    /// [RFC5766#section-5](https://tools.ietf.org/html/rfc5766#section-5)
    case allocateRequest = 0x003
    case allocateResponse = 0x0103
    case allocateErrorResponse = 0x0113
    /// [RFC5766#section-7](https://tools.ietf.org/html/rfc5766#section-7)
    case refreshRequest = 0x004
    case refreshResponse = 0x0104
    case refreshErrorResponse = 0x0114
    /// [RFC5766#section-10](https://tools.ietf.org/html/rfc5766#section-10)
    case sendIndication = 0x016
    case dataIndication = 0x017
    /// [RFC5766#section-8](https://tools.ietf.org/html/rfc5766#section-8)
    case createPermissionRequest = 0x008
    case createPermissionResponse = 0x0108
    case createPermissionErrorResponse = 0x0118
    /// [RFC5766#section-11](https://tools.ietf.org/html/rfc5766#section-11)
    case channelBindRequest = 0x009
    case channelBindResponse = 0x0109
    case channelBindErrorResponse = 0x0119

    /// A Boolean value indicating whether the message is an indication.
    public var isIndication: Bool {
      rawValue & 0x0110 == 0x010
    }
  }
}
