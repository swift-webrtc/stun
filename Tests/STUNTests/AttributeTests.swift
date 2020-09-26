//
//  AttributeTests.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

@testable
import STUN
import Network
import Core
import XCTest

final class AttributeTests: XCTestCase {

  func testString() throws {
    var message = STUNMessage(type: .bindingRequest)
    message.append(.init(type: .username, value: .string("webrtc")))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .username)
      XCTAssertEqual(attribute?.value.string, "webrtc")
    }
  }

  func testAddressV4() throws {
    let address = SocketAddress(ip: .v4(.localhost), port: 3578)
    var message = STUNMessage(type: .bindingResponse)
    message.append(.init(type: .mappedAddress, value: .address(address)))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .mappedAddress)
      XCTAssertEqual(attribute?.value.address, address)
    }
  }

  func testAddressV6() throws {
    let address = SocketAddress(ip: .v6(.localhost), port: 3578)
    var message = STUNMessage(type: .bindingResponse)
    message.append(.init(type: .mappedAddress, value: .address(address)))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .mappedAddress)
      XCTAssertEqual(attribute?.value.address, address)
    }
  }

  func testXorAddressV4() throws {
    let address = SocketAddress(ip: .v4(.localhost), port: 3578)
    var message = STUNMessage(type: .bindingResponse)
    message.append(.init(type: .xorMappedAddress, value: .xorAddress(address)))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .xorMappedAddress)
      XCTAssertEqual(attribute?.value.address, address)
    }
  }

  func testXorAddressV6() throws {
    let address = SocketAddress(ip: .v6(.localhost), port: 3578)
    var message = STUNMessage(type: .bindingResponse)
    message.append(.init(type: .xorMappedAddress, value: .xorAddress(address)))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .xorMappedAddress)
      XCTAssertEqual(attribute?.value.address, address)
    }
  }

  func testChannel() throws {
    var message = STUNMessage(type: .bindingRequest)
    message.append(.init(type: .channelNumber, value: .uint32(UInt32(UInt16.max))))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .channelNumber)
      XCTAssertEqual(attribute?.value.integer, Int(UInt16.max))
    }
  }

  func testErrorCode() throws {
    var message = STUNMessage(type: .bindingErrorResponse)
    message.append(.init(type: .errorCode, value: .errorCode(.badRequest)))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .errorCode)
      XCTAssertEqual(attribute?.value.errorCode, .badRequest)
    }
  }

  func testUnknownAttributes() throws {
    var message = STUNMessage(type: .bindingErrorResponse)
    message.append(.unknownAttributes([.nonce, .realm, .username]))
    try message.withUnsafeBytes {
      let attribute = try STUNMessage(bytes: Array($0)).attribute(for: .unknownAttributes)
      XCTAssertEqual(attribute?.value.uint16List, [STUNAttribute.Kind.nonce, STUNAttribute.Kind.realm, STUNAttribute.Kind.username].map(\.rawValue))
    }
  }

  func testShortMessageIntegrity() throws {
    let credential = STUNCredential.short(password: "webrtc")
    var message = STUNMessage(type: .bindingRequest)
    message.append(.messageIntegrity(credential))
    XCTAssertTrue(try STUNMessage(bytes: message.withUnsafeBytes(Array.init)).validateMessageIntegrity(credential))
  }

  func testLongMessageIntegrity() throws {
    let credential = STUNCredential.long(username: "webrtc", password: "webrtc", realm: "webrtc")
    var message = STUNMessage(type: .bindingRequest)
    message.append(.messageIntegrity(credential))
    XCTAssertTrue(try STUNMessage(bytes: message.withUnsafeBytes(Array.init)).validateMessageIntegrity(credential))
  }

  func testFingerprint() throws {
    var message = STUNMessage(type: .bindingRequest)
    message.append(.init(type: .username, value: .string("webrtc")))
    message.append(.fingerprint())
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
