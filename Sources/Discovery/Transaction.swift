//
//  Transaction.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/10/25.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN
import Network
import Core
import Dispatch

internal final class Transaction {
  internal var id: STUNTransactionId
  internal var raw: Array<UInt8>
  internal var destinationAddress: SocketAddress
  internal var handler: STUNRequestHandler?
  internal var rto: Duration
  internal var attemptCount: Int = 0
  internal var timeoutTask: DispatchWorkItem

  internal init(
    id: STUNTransactionId,
    raw: Array<UInt8>,
    destinationAddress: SocketAddress,
    handler: STUNRequestHandler?,
    rto: Duration,
    timeoutHandler: @escaping (STUNTransactionId) -> Void
  ) {
    self.id = id
    self.raw = raw
    self.destinationAddress = destinationAddress
    self.handler = handler
    self.rto = rto
    self.timeoutTask = DispatchWorkItem {
      timeoutHandler(id)
    }
  }

  internal func start(socket: UDPSocket, queue: DispatchQueue) throws {
    _ = try raw.withUnsafeBytes {
      try socket.sendto($0, address: destinationAddress)
    }
    queue.asyncAfter(deadline: .now() + .milliseconds(min(rto.milliseconds << attemptCount, 8000)), execute: timeoutTask)
  }
}

// MARK: - Transaction + Equatable

extension Transaction: Equatable {

  internal static func == (lhs: Transaction, rhs: Transaction) -> Bool {
    lhs.id == rhs.id
  }
}
