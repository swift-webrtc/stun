//
//  Value.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/10/25.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

public protocol STUNAttributeValueCodable {
  var bytes: Array<UInt8> { get }

  init?(from bytes: Array<UInt8>)
}

extension Int: STUNAttributeValueCodable {}
extension Int8: STUNAttributeValueCodable {}
extension Int16: STUNAttributeValueCodable {}
extension Int32: STUNAttributeValueCodable {}
extension Int64: STUNAttributeValueCodable {}
extension UInt: STUNAttributeValueCodable {}
extension UInt8: STUNAttributeValueCodable {}
extension UInt16: STUNAttributeValueCodable {}
extension UInt32: STUNAttributeValueCodable {}
extension UInt64: STUNAttributeValueCodable {}

extension STUNAttributeValueCodable where Self: FixedWidthInteger {
  public var bytes: Array<UInt8> {
    withUnsafeBytes(of: bigEndian, Array.init)
  }

  public init?(from bytes: Array<UInt8>) {
    guard bytes.count == MemoryLayout<Self>.size else {
      return nil
    }
    self = Self(bigEndianBytes: bytes)
  }
}

extension String: STUNAttributeValueCodable {

  public init?(from bytes: Array<UInt8>) {
    self = Self(decoding: bytes, as: UTF8.self)
  }
}
