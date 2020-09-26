//
//  Transaction.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/20.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Core
import Dispatch

internal final class STUNTransaction {
  internal var id: STUNTransactionId
  internal var raw: Array<UInt8>
  internal var handler: STUNClient.RequestHandler?
  internal var rto: Duration
  internal var attempt: Int = 0
  internal var timeoutTask: DispatchWorkItem

  internal init(
    id: STUNTransactionId,
    raw: Array<UInt8>,
    handler: STUNClient.RequestHandler?,
    rto: Duration,
    timeoutHandler: @escaping (STUNTransactionId) -> Void
  ) {
    self.id = id
    self.raw = raw
    self.handler = handler
    self.rto = rto
    self.timeoutTask = DispatchWorkItem {
      timeoutHandler(id)
    }
  }

  internal func start(on queue: DispatchQueue) {
    queue.asyncAfter(deadline: .now() + .nanoseconds((attempt + 1) * rto.nanoseconds), execute: timeoutTask)
  }
}

// MARK: - STUNTransaction + Equatable

extension STUNTransaction: Equatable {

  internal static func ==(lhs: STUNTransaction, rhs: STUNTransaction) -> Bool {
    lhs.id == rhs.id
  }
}
