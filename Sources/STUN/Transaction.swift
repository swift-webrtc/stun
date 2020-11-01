//
//  Transaction.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/20.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

internal final class Transaction {
  internal var message: STUNMessage
  internal var address: SocketAddress
  internal var handler: STUNResponseHandler?
  internal var rto: Duration
  internal var attemptCount: Int = 0
  internal var timeoutHandler: (Transaction) -> Void
  internal var timeoutTask: Cancellable?

  internal init(
    message: STUNMessage,
    address: SocketAddress,
    handler: STUNResponseHandler?,
    rto: Duration,
    timeoutHandler: @escaping (Transaction) -> Void
  ) {
    self.message = message
    self.address = address
    self.handler = handler
    self.rto = rto
    self.timeoutHandler = timeoutHandler
  }

  deinit {
    logger.debug("\(self) is deinit", metadata: ["transactionId": "\(message.transactionId)"])
  }

  internal func start(on eventLoop: EventLoop) {
    let delay = min(rto.milliseconds << attemptCount, 8000)
    timeoutTask = eventLoop.schedule(delay: .milliseconds(delay)) { [self] _ in
      timeoutHandler(self)
    }
  }

  internal func cancel() {
    timeoutTask?.cancel()
    timeoutTask = nil
  }

  internal func onSuccess(_ value: STUNMessage) {
    handler?(.success(value))
    handler = nil
  }

  internal func onError(_ error: Error) {
    handler?(.failure(error))
    handler = nil
  }
}

// MARK: - Transaction + Equatable

extension Transaction: Equatable {

  internal static func == (lhs: Transaction, rhs: Transaction) -> Bool {
    lhs.message.transactionId == rhs.message.transactionId
  }
}
