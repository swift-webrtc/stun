//
//  Address.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Network
import Core

// MARK: - Decode

extension SocketAddress {

  /// [RFC5389#section-15.1](https://tools.ietf.org/html/rfc5389#section-15.1)
  internal init(bytes: Array<UInt8>) throws {
    var reader = ByteReader(bytes)
    guard let family = reader.readInteger(as: UInt16.self), let port = reader.readInteger(as: UInt16.self) else {
      throw STUNError.invalidAddressValue
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
      throw STUNError.invalidAddressValue
    }
  }

  /// [RFC5389#section-15.2](https://tools.ietf.org/html/rfc5389#section-15.2)
  internal init(bytes: Array<UInt8>, transactionId: STUNTransactionId) throws {
    var reader = ByteReader(bytes)
    guard let family = reader.readInteger(as: UInt16.self), let port = reader.readInteger(as: UInt16.self) else {
      throw STUNError.invalidAddressValue
    }

    switch family {
    case 0x01 where reader.count == 4:
      self = .init(
        ip: .v4(
          IPv4Address((reader.readInteger(as: UInt32.self)! ^ STUNMessage.magicCookie).bigEndian)
        ),
        port: Port(rawValue: port ^ UInt16(STUNMessage.magicCookie >> 16))!
      )
    case 0x02 where reader.count == 16:
      self = .init(
        ip: .v6(
          transactionId.raw.withUnsafeBytes {
            let ids = $0.bindMemory(to: UInt32.self)
            return IPv6Address(
              reader.readInteger(as: UInt32.self)! ^ STUNMessage.magicCookie,
              reader.readInteger(as: UInt32.self)! ^ ids[0].bigEndian,
              reader.readInteger(as: UInt32.self)! ^ ids[1].bigEndian,
              reader.readInteger(as: UInt32.self)! ^ ids[2].bigEndian
            )
          }
        ),
        port: Port(rawValue: port ^ UInt16(STUNMessage.magicCookie >> 16))!
      )
    default:
      throw STUNError.invalidAddressValue
    }
  }
}

// MARK: - Encode

extension SocketAddress {

  internal var bytes: Array<UInt8> {
    var writer = ByteWriter(capacity: ip.isIPv4 ? 8 : 20)
    writer.writeInteger(ip.isIPv4 ? 0x0001 : 0x0002, as: UInt16.self)
    writer.writeInteger(port.rawValue)
    writer.writeBytes(ip.octets)
    return writer.withUnsafeBytes(Array.init)
  }
}
