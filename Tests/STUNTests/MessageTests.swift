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
    let message = STUNMessage(type: .init(method: .binding, class: .request))
    var reader = ByteReader(writer: message.raw)
    XCTAssertEqual(reader.readInteger(as: UInt16.self), STUNMessage.Kind(method: .binding, class: .request).rawValue)
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
    XCTAssertEqual(message.type, .init(method: .binding, class: .request))
    XCTAssertEqual(message.length, 0)
    XCTAssertEqual(message.magicCookie, STUNMessage.magicCookie)
    XCTAssertEqual(message.transactionId, .init(raw: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D]))
  }

  func testMessagetype() {
    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .request).rawValue == 0x001)
    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .indication).rawValue == 0x011)
    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .response).rawValue == 0x101)
    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .errorResponse).rawValue == 0x111)
    XCTAssertTrue(STUNMessage.Kind(method: .allocate, class: .request).rawValue == 0x003)
    XCTAssertTrue(STUNMessage.Kind(method: .allocate, class: .response).rawValue == 0x0103)
    XCTAssertTrue(STUNMessage.Kind(method: .allocate, class: .errorResponse).rawValue == 0x0113)
    XCTAssertTrue(STUNMessage.Kind(method: .refresh, class: .request).rawValue == 0x004)
    XCTAssertTrue(STUNMessage.Kind(method: .refresh, class: .response).rawValue == 0x0104)
    XCTAssertTrue(STUNMessage.Kind(method: .refresh, class: .errorResponse).rawValue == 0x0114)
    XCTAssertTrue(STUNMessage.Kind(method: .send, class: .indication).rawValue == 0x016)
    XCTAssertTrue(STUNMessage.Kind(method: .data, class: .indication).rawValue == 0x017)
    XCTAssertTrue(STUNMessage.Kind(method: .createPermission, class: .request).rawValue == 0x008)
    XCTAssertTrue(STUNMessage.Kind(method: .createPermission, class: .response).rawValue == 0x108)
    XCTAssertTrue(STUNMessage.Kind(method: .createPermission, class: .errorResponse).rawValue == 0x118)
    XCTAssertTrue(STUNMessage.Kind(method: .channelBind, class: .request).rawValue == 0x009)
    XCTAssertTrue(STUNMessage.Kind(method: .channelBind, class: .response).rawValue == 0x109)
    XCTAssertTrue(STUNMessage.Kind(method: .channelBind, class: .errorResponse).rawValue == 0x119)

    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .request) == STUNMessage.Kind(rawValue: 0x001))
    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .indication) == STUNMessage.Kind(rawValue: 0x011))
    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .response) == STUNMessage.Kind(rawValue: 0x101))
    XCTAssertTrue(STUNMessage.Kind(method: .binding, class: .errorResponse) == STUNMessage.Kind(rawValue: 0x111))
    XCTAssertTrue(STUNMessage.Kind(method: .allocate, class: .request) == STUNMessage.Kind(rawValue: 0x003))
    XCTAssertTrue(STUNMessage.Kind(method: .allocate, class: .response) == STUNMessage.Kind(rawValue: 0x0103))
    XCTAssertTrue(STUNMessage.Kind(method: .allocate, class: .errorResponse) == STUNMessage.Kind(rawValue: 0x0113))
    XCTAssertTrue(STUNMessage.Kind(method: .refresh, class: .request) == STUNMessage.Kind(rawValue: 0x004))
    XCTAssertTrue(STUNMessage.Kind(method: .refresh, class: .response) == STUNMessage.Kind(rawValue: 0x0104))
    XCTAssertTrue(STUNMessage.Kind(method: .refresh, class: .errorResponse) == STUNMessage.Kind(rawValue: 0x0114))
    XCTAssertTrue(STUNMessage.Kind(method: .send, class: .indication) == STUNMessage.Kind(rawValue: 0x016))
    XCTAssertTrue(STUNMessage.Kind(method: .data, class: .indication) == STUNMessage.Kind(rawValue: 0x017))
    XCTAssertTrue(STUNMessage.Kind(method: .createPermission, class: .request) == STUNMessage.Kind(rawValue: 0x008))
    XCTAssertTrue(STUNMessage.Kind(method: .createPermission, class: .response) == STUNMessage.Kind(rawValue: 0x108))
    XCTAssertTrue(STUNMessage.Kind(method: .createPermission, class: .errorResponse) == STUNMessage.Kind(rawValue: 0x118))
    XCTAssertTrue(STUNMessage.Kind(method: .channelBind, class: .request) == STUNMessage.Kind(rawValue: 0x009))
    XCTAssertTrue(STUNMessage.Kind(method: .channelBind, class: .response) == STUNMessage.Kind(rawValue: 0x109))
    XCTAssertTrue(STUNMessage.Kind(method: .channelBind, class: .errorResponse) == STUNMessage.Kind(rawValue: 0x119))
  }

  static var allTests = [
    ("testEncodeMessage", testEncodeMessage),
    ("testDecodeMessageHeader", testDecodeMessage),
    ("testMessagetype", testMessagetype),
  ]
}
