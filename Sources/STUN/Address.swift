//
//  Address.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

/// [RFC5389#section-15.1](https://tools.ietf.org/html/rfc5389#section-15.1)
public typealias STUNAddress = SocketAddress

// MARK: - STUNAddress + STUNAttributeValueCodable

extension STUNAddress: STUNAttributeValueCodable {
  public var bytes: Array<UInt8> {
    var writer = ByteWriter(capacity: ip.isIPv4 ? 8 : 20)
    writer.writeInteger(ip.isIPv4 ? 0x0001 : 0x0002, as: UInt16.self)
    writer.writeInteger(port.rawValue)
    writer.writeBytes(ip.octets)
    return writer.withUnsafeBytes(Array.init)
  }

  public init?(from bytes: Array<UInt8>) {
    var reader = ByteReader(bytes)
    guard let family = reader.readInteger(as: UInt16.self), let port = reader.readInteger(as: UInt16.self) else {
      return nil
    }

    switch family {
    case 0x01 where reader.count == 4:
      self = .init(
        ip: .v4(IPv4Address(reader.readInteger(as: UInt32.self)!.bigEndian)),
        port: Port(rawValue: port)!
      )
    case 0x02 where reader.count == 16:
      self = .init(
        ip: .v6(
          IPv6Address(
            reader.readInteger(as: UInt32.self)!,
            reader.readInteger(as: UInt32.self)!,
            reader.readInteger(as: UInt32.self)!,
            reader.readInteger(as: UInt32.self)!
          )
        ),
        port: Port(rawValue: port)!
      )
    default:
      return nil
    }
  }
}

// MARK: - STUNXorAddress

/// [RFC5389#section-15.2](https://tools.ietf.org/html/rfc5389#section-15.2)
public struct STUNXorAddress {
  public var address: STUNAddress

  public init(_ address: STUNAddress) {
    self.address = address
  }
}

// MARK: - STUNXorAddress + STUNAttributeValueCodable

extension STUNXorAddress: CustomStringConvertible {
  public var description: String {
    address.description
  }
}

// MARK: - STUNXorAddress + STUNAttributeValueCodable

extension STUNXorAddress: STUNAttributeValueCodable {
  public var bytes: Array<UInt8> {
    address.bytes
  }

  public init?(from bytes: Array<UInt8>) {
    guard let address = STUNAddress(from: bytes) else {
      return nil
    }
    self.address = address
  }
}
