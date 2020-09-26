//
//  TransactionId.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/15.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Core

/// The transaction ID is a 96-bit identifier, used to uniquely identify STUN transactions.
public struct STUNTransactionId: Equatable, Hashable {
  internal var raw: Array<UInt8>

  internal init(raw: Array<UInt8>) {
    precondition(raw.count == 12)
    self.raw = raw
  }

  public init() {
    var rng = SystemRandomNumberGenerator()
    var writer = ByteWriter(capacity: 12)
    writer.writeInteger(rng.next(), as: UInt64.self)
    writer.writeInteger(rng.next(), as: UInt32.self)
    self.raw = writer.withUnsafeBytes(Array.init)
  }
}

// MARK: - STUNTransactionId + CustomStringConvertible

extension STUNTransactionId: CustomStringConvertible {
  public var description: String {
    raw.hex.uppercased()
  }
}
