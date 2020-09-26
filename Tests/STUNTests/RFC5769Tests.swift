//
//  RFC5769Tests.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/13.
//  Copyright © 2020 sunlubo. All rights reserved.
//

@testable
import STUN
import Network
import Core
import XCTest

final class RFC5769Tests: XCTestCase {

  func testRequest() throws {
    let bytes: Array<UInt8> = [
      0x00, 0x01, 0x00, 0x58, //    Request type and message length
      0x21, 0x12, 0xa4, 0x42, //    Magic cookie
      0xb7, 0xe7, 0xa7, 0x01, // }
      0xbc, 0x34, 0xd6, 0x86, // }  Transaction ID
      0xfa, 0x87, 0xdf, 0xae, // }
      0x80, 0x22, 0x00, 0x10, //    SOFTWARE attribute header
      0x53, 0x54, 0x55, 0x4e, // }
      0x20, 0x74, 0x65, 0x73, // }  User-agent...
      0x74, 0x20, 0x63, 0x6c, // }  ...name
      0x69, 0x65, 0x6e, 0x74, // }
      0x00, 0x24, 0x00, 0x04, //    PRIORITY attribute header
      0x6e, 0x00, 0x01, 0xff, //    ICE priority value
      0x80, 0x29, 0x00, 0x08, //    ICE-CONTROLLED attribute header
      0x93, 0x2f, 0xf9, 0xb1, // }  Pseudo-random tie breaker...
      0x51, 0x26, 0x3b, 0x36, // }  ...for ICE control
      0x00, 0x06, 0x00, 0x09, //    USERNAME attribute header,     //
      0x65, 0x76, 0x74, 0x6a, // }
      0x3a, 0x68, 0x36, 0x76, // }  Username (9 bytes) and padding (3 bytes)
      0x59, 0x20, 0x20, 0x20, // }
      0x00, 0x08, 0x00, 0x14, //    MESSAGE-INTEGRITY attribute header
      0x9a, 0xea, 0xa7, 0x0c, // }
      0xbf, 0xd8, 0xcb, 0x56, // }
      0x78, 0x1e, 0xf2, 0xb5, // }  HMAC-SHA1 fingerprint
      0xb2, 0xd3, 0xf2, 0x49, // }
      0xc1, 0xb5, 0x71, 0xa2, // }
      0x80, 0x28, 0x00, 0x04, //    FINGERPRINT attribute header
      0xe5, 0x7a, 0x3b, 0xcf, //    CRC32 fingerprint
    ]
    let message = try STUNMessage(bytes: bytes)
    XCTAssertEqual(message.type.rawValue, 0x0001)
    XCTAssertEqual(message.length, 0x58)
    XCTAssertEqual(message.magicCookie, STUNMessage.magicCookie)
    XCTAssertEqual(message.transactionId, .init(raw: [0xb7, 0xe7, 0xa7, 0x01, 0xbc, 0x34, 0xd6, 0x86, 0xfa, 0x87, 0xdf, 0xae]))

    let software = message.attribute(for: .software)?.value.string
    XCTAssertEqual(software, "STUN test client")

    let username = message.attribute(for: .username)?.value.string
    XCTAssertEqual(username, "evtj:h6vY")

    XCTAssertTrue(message.validateMessageIntegrity(.short(password: "VOkJxbRl1RmTxUk/WvJxBt")))
    XCTAssertTrue(message.validateFingerprint())
  }

  func testIPv4Response() throws {
    let bytes: Array<UInt8> = [
      0x01, 0x01, 0x00, 0x3c, //    Response type and message length
      0x21, 0x12, 0xa4, 0x42, //    Magic cookie
      0xb7, 0xe7, 0xa7, 0x01, // }
      0xbc, 0x34, 0xd6, 0x86, // }  Transaction ID
      0xfa, 0x87, 0xdf, 0xae, // }
      0x80, 0x22, 0x00, 0x0b, //    SOFTWARE attribute header
      0x74, 0x65, 0x73, 0x74, // }
      0x20, 0x76, 0x65, 0x63, // }  UTF-8 server name
      0x74, 0x6f, 0x72, 0x20, // }
      0x00, 0x20, 0x00, 0x08, //    XOR-MAPPED-ADDRESS attribute header
      0x00, 0x01, 0xa1, 0x47, //    Address family (IPv4) and xor'd mapped port number
      0xe1, 0x12, 0xa6, 0x43, //    Xor'd mapped IPv4 address
      0x00, 0x08, 0x00, 0x14, //    MESSAGE-INTEGRITY attribute header
      0x2b, 0x91, 0xf5, 0x99, // }
      0xfd, 0x9e, 0x90, 0xc3, // }
      0x8c, 0x74, 0x89, 0xf9, // }  HMAC-SHA1 fingerprint
      0x2a, 0xf9, 0xba, 0x53, // }
      0xf0, 0x6b, 0xe7, 0xd7, // }
      0x80, 0x28, 0x00, 0x04, //    FINGERPRINT attribute header
      0xc0, 0x7d, 0x4c, 0x96, //    CRC32 fingerprint
    ]
    let message = try STUNMessage(bytes: bytes)
    XCTAssertEqual(message.type.rawValue, 0x0101)
    XCTAssertEqual(message.length, 0x3c)
    XCTAssertEqual(message.magicCookie, STUNMessage.magicCookie)
    XCTAssertEqual(message.transactionId, .init(raw: [0xb7, 0xe7, 0xa7, 0x01, 0xbc, 0x34, 0xd6, 0x86, 0xfa, 0x87, 0xdf, 0xae]))

    let software = message.attribute(for: .software)?.value.string
    XCTAssertEqual(software, "test vector")

    let address = message.attribute(for: .xorMappedAddress)?.value.address
    XCTAssertEqual(address, SocketAddress(ip: .v4(IPv4Address("192.0.2.1")!), port: 32853))

    XCTAssertTrue(message.validateMessageIntegrity(.short(password: "VOkJxbRl1RmTxUk/WvJxBt")))
    XCTAssertTrue(message.validateFingerprint())
  }

  func testIPv6Response() throws {
    let bytes: Array<UInt8> = [
      0x01, 0x01, 0x00, 0x48, //    Response type and message length
      0x21, 0x12, 0xa4, 0x42, //    Magic cookie
      0xb7, 0xe7, 0xa7, 0x01, // }
      0xbc, 0x34, 0xd6, 0x86, // }  Transaction ID
      0xfa, 0x87, 0xdf, 0xae, // }
      0x80, 0x22, 0x00, 0x0b, //    SOFTWARE attribute header
      0x74, 0x65, 0x73, 0x74, // }
      0x20, 0x76, 0x65, 0x63, // }  UTF-8 server name
      0x74, 0x6f, 0x72, 0x20, // }
      0x00, 0x20, 0x00, 0x14, //    XOR-MAPPED-ADDRESS attribute header
      0x00, 0x02, 0xa1, 0x47, //    Address family (IPv6) and xor'd mapped port number
      0x01, 0x13, 0xa9, 0xfa, // }
      0xa5, 0xd3, 0xf1, 0x79, // }  Xor'd mapped IPv6 address
      0xbc, 0x25, 0xf4, 0xb5, // }
      0xbe, 0xd2, 0xb9, 0xd9, // }
      0x00, 0x08, 0x00, 0x14, //    MESSAGE-INTEGRITY attribute header
      0xa3, 0x82, 0x95, 0x4e, // }
      0x4b, 0xe6, 0x7b, 0xf1, // }
      0x17, 0x84, 0xc9, 0x7c, // }  HMAC-SHA1 fingerprint
      0x82, 0x92, 0xc2, 0x75, // }
      0xbf, 0xe3, 0xed, 0x41, // }
      0x80, 0x28, 0x00, 0x04, //    FINGERPRINT attribute header
      0xc8, 0xfb, 0x0b, 0x4c, //    CRC32 fingerprint
    ]
    let message = try STUNMessage(bytes: bytes)
    XCTAssertEqual(message.type.rawValue, 0x0101)
    XCTAssertEqual(message.length, 0x48)
    XCTAssertEqual(message.magicCookie, STUNMessage.magicCookie)
    XCTAssertEqual(message.transactionId, .init(raw: [0xb7, 0xe7, 0xa7, 0x01, 0xbc, 0x34, 0xd6, 0x86, 0xfa, 0x87, 0xdf, 0xae]))

    let software = message.attribute(for: .software)?.value.string
    XCTAssertEqual(software, "test vector")

    let address = message.attribute(for: .xorMappedAddress)?.value.address
    XCTAssertEqual(address, SocketAddress(ip: .v6(IPv6Address("2001:db8:1234:5678:11:2233:4455:6677")!), port: 32853))

    XCTAssertTrue(message.validateMessageIntegrity(.short(password: "VOkJxbRl1RmTxUk/WvJxBt")))
    XCTAssertTrue(message.validateFingerprint())
  }

  func testRequestWithLongTermAuthentication() throws {
    let bytes: Array<UInt8> = [
      0x00, 0x01, 0x00, 0x60, //    Request type and message length
      0x21, 0x12, 0xa4, 0x42, //    Magic cookie
      0x78, 0xad, 0x34, 0x33, // }
      0xc6, 0xad, 0x72, 0xc0, // }  Transaction ID
      0x29, 0xda, 0x41, 0x2e, // }
      0x00, 0x06, 0x00, 0x12, //    USERNAME attribute header
      0xe3, 0x83, 0x9e, 0xe3, // }
      0x83, 0x88, 0xe3, 0x83, // }
      0xaa, 0xe3, 0x83, 0x83, // }  Username value (18 bytes) and padding (2 bytes)
      0xe3, 0x82, 0xaf, 0xe3, // }
      0x82, 0xb9, 0x00, 0x00, // }
      0x00, 0x15, 0x00, 0x1c, //    NONCE attribute header
      0x66, 0x2f, 0x2f, 0x34, // }
      0x39, 0x39, 0x6b, 0x39, // }
      0x35, 0x34, 0x64, 0x36, // }
      0x4f, 0x4c, 0x33, 0x34, // }  Nonce value
      0x6f, 0x4c, 0x39, 0x46, // }
      0x53, 0x54, 0x76, 0x79, // }
      0x36, 0x34, 0x73, 0x41, // }
      0x00, 0x14, 0x00, 0x0b, //    REALM attribute header
      0x65, 0x78, 0x61, 0x6d, // }
      0x70, 0x6c, 0x65, 0x2e, // }  Realm value (11 bytes) and padding (1 byte)
      0x6f, 0x72, 0x67, 0x00, // }
      0x00, 0x08, 0x00, 0x14, //    MESSAGE-INTEGRITY attribute header
      0xf6, 0x70, 0x24, 0x65, // }
      0x6d, 0xd6, 0x4a, 0x3e, // }
      0x02, 0xb8, 0xe0, 0x71, // }  HMAC-SHA1 fingerprint
      0x2e, 0x85, 0xc9, 0xa2, // }
      0x8c, 0xa8, 0x96, 0x66, // }
    ]
    let message = try STUNMessage(bytes: bytes)
    XCTAssertEqual(message.type.rawValue, 0x0001)
    XCTAssertEqual(message.length, 0x60)
    XCTAssertEqual(message.magicCookie, STUNMessage.magicCookie)
    XCTAssertEqual(message.transactionId, .init(raw: [0x78, 0xad, 0x34, 0x33, 0xc6, 0xad, 0x72, 0xc0, 0x29, 0xda, 0x41, 0x2e]))

    let username = message.attribute(for: .username)?.value.string
    XCTAssertEqual(username, "\u{30DE}\u{30C8}\u{30EA}\u{30C3}\u{30AF}\u{30B9}")

    let nonce = message.attribute(for: .nonce)?.value.string
    XCTAssertEqual(nonce, "f//499k954d6OL34oL9FSTvy64sA")

    let realm = message.attribute(for: .realm)?.value.string
    XCTAssertEqual(realm, "example.org")

    XCTAssertTrue(message.validateMessageIntegrity(.long(username: username!, password: "TheMatrIX", realm: realm!)))
  }

  static var allTests = [
    ("testRequest", testRequest),
    ("testIPv4Response", testIPv4Response),
    ("testIPv6Response", testIPv6Response),
    ("testRequestWithLongTermAuthentication", testRequestWithLongTermAuthentication),
  ]
}
