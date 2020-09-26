//
//  MessageTests.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/12.
//  Copyright © 2020 sunlubo. All rights reserved.
//

@testable
import STUN
import Core
import XCTest

final class MessageTests: XCTestCase {

  func testEncodeMessage() {
    let message = STUNMessage(type: .bindingRequest)
    var reader = ByteReader(writer: message.raw)
    XCTAssertEqual(reader.readInteger(as: UInt16.self), STUNMessage.Kind.bindingRequest.rawValue)
    XCTAssertEqual(reader.readInteger(as: UInt16.self), 0)
    XCTAssertEqual(reader.readInteger(as: UInt32.self), STUNMessage.magicCookie)
    XCTAssertEqual(reader.readBytes(count: 12), message.transactionId.raw)
    XCTAssertEqual(reader.count, 0)
  }

  func testDecodeMessage() throws {
    let message = try STUNMessage(bytes: [
      0x00, 0x01, 0x00, 0x00, 0x21, 0x12, 0xA4, 0x42, 0x01, 0x02,
      0x03, 0x04, 0x05, 0x06, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
    ])
    XCTAssertEqual(message.type, .bindingRequest)
    XCTAssertEqual(message.length, 0)
    XCTAssertEqual(message.magicCookie, STUNMessage.magicCookie)
    XCTAssertEqual(message.transactionId, .init(raw: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D]))
  }

  func testMessagetype() {
    XCTAssertTrue(STUNMessage.Kind.bindingIndication.isIndication)
    XCTAssertTrue(STUNMessage.Kind.sendIndication.isIndication)
    XCTAssertTrue(STUNMessage.Kind.dataIndication.isIndication)
    XCTAssertFalse(STUNMessage.Kind.bindingRequest.isIndication)
    XCTAssertFalse(STUNMessage.Kind.bindingResponse.isIndication)
  }

  static var allTests = [
    ("testEncodeMessage", testEncodeMessage),
    ("testDecodeMessageHeader", testDecodeMessage),
    ("testMessagetype", testMessagetype),
  ]
}
