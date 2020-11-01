//
//  AttributeTests.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

@testable
import STUN
import AsyncIO
import Core
import XCTest

final class AttributeTests: XCTestCase {

  func testString() throws {
    var message = STUNMessage(type: .init(method: .binding, class: .request))
    message.appendAttribute(type: .username, value: "webrtc")
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .username), "webrtc")
    }
  }

  func testAddressV4() throws {
    let address = STUNAddress(ip: .v4(.localhost), port: 3578)
    var message = STUNMessage(type: .init(method: .binding, class: .response))
    message.appendAttribute(type: .mappedAddress, value: address)
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .mappedAddress, as: STUNAddress.self), address)
    }
  }

  func testAddressV6() throws {
    let address = STUNAddress(ip: .v6(.localhost), port: 3578)
    var message = STUNMessage(type: .init(method: .binding, class: .response))
    message.appendAttribute(type: .mappedAddress, value: address)
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .mappedAddress, as: STUNAddress.self), address)
    }
  }

  func testXorAddressV4() throws {
    let address = STUNAddress(ip: .v4(.localhost), port: 3578)
    var message = STUNMessage(type: .init(method: .binding, class: .response))
    message.appendAttribute(type: .xorMappedAddress, value: STUNXorAddress(address))
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .xorMappedAddress, as: STUNXorAddress.self)?.address, address)
    }
  }

  func testXorAddressV6() throws {
    let address = STUNAddress(ip: .v6(.localhost), port: 3578)
    var message = STUNMessage(type: .init(method: .binding, class: .response))
    message.appendAttribute(type: .xorMappedAddress, value: STUNXorAddress(address))
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .xorMappedAddress, as: STUNXorAddress.self)?.address, address)
    }
  }

  func testChannel() throws {
    var message = STUNMessage(type: .init(method: .binding, class: .request))
    message.appendAttribute(type: .channelNumber, value: UInt32(UInt16.max))
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .channelNumber), UInt32(UInt16.max))
    }
  }

  func testErrorCode() throws {
    var message = STUNMessage(type: .init(method: .binding, class: .errorResponse))
    message.appendAttribute(type: .errorCode, value: STUNErrorCode.badRequest)
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .errorCode), STUNErrorCode.badRequest)
    }
  }

  func testUnknownAttributes() throws {
    var message = STUNMessage(type: .init(method: .binding, class: .errorResponse))
    message.appendAttribute(type: .unknownAttributes, value: [.nonce, .realm, .username])
    try message.withUnsafeBytes {
      XCTAssertEqual(try STUNMessage(bytes: Array($0)).attributeValue(for: .unknownAttributes), [.nonce, .realm, .username])
    }
  }

  func testShortMessageIntegrity() throws {
    let credential = STUNCredential.short(password: "webrtc")
    var message = STUNMessage(type: .init(method: .binding, class: .request))
    message.appendMessageIntegrity(credential)
    XCTAssertTrue(try STUNMessage(bytes: message.withUnsafeBytes(Array.init)).validateMessageIntegrity(credential))
  }

  func testLongMessageIntegrity() throws {
    let credential = STUNCredential.long(username: "webrtc", password: "webrtc", realm: "webrtc")
    var message = STUNMessage(type: .init(method: .binding, class: .request))
    message.appendMessageIntegrity(credential)
    XCTAssertTrue(try STUNMessage(bytes: message.withUnsafeBytes(Array.init)).validateMessageIntegrity(credential))
  }

  func testFingerprint() throws {
    var message = STUNMessage(type: .init(method: .binding, class: .request))
    message.appendAttribute(type: .username, value: "webrtc")
    message.appendFingerprint()
    XCTAssertTrue(try STUNMessage(bytes: message.withUnsafeBytes(Array.init)).validateFingerprint())
  }

  static var allTests = [
    ("testString", testString),
    ("testAddressV4", testAddressV4),
    ("testAddressV6", testAddressV6),
    ("testXorAddressV4", testXorAddressV4),
    ("testXorAddressV6", testXorAddressV6),
    ("testChannel", testChannel),
    ("testErrorCode", testErrorCode),
    ("testUnknownAttributes", testUnknownAttributes),
    ("testShortMessageIntegrity", testShortMessageIntegrity),
    ("testLongMessageIntegrity", testLongMessageIntegrity),
    ("testFingerprint", testFingerprint),
  ]
}
