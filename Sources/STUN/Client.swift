//
//  Client.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

public typealias STUNResponseHandler = (Result<STUNMessage, Error>) -> Void
public typealias STUNIndicationHandler = (STUNMessage) -> Void

/// [ Session Traversal Utilities for NAT (STUN)](https://tools.ietf.org/html/rfc5389)
public final class STUNClient {
  internal var configuration: Configuration
  internal var transactions: [STUNTransactionId: Transaction] = [:]
  internal var socket: UDPSocket

  public var localAddress: SocketAddress? {
    socket.localAddress
  }

  public init(configuration: Configuration) {
    self.configuration = configuration
    self.socket = UDPSocket(eventLoop: configuration.eventLoop)
    self.socket.delegate = self
  }

  deinit {
    logger.debug("\(self) is deinit")
  }

  public func bind(to address: SocketAddress = SocketAddress(ip: .v4(.any), port: 0)) throws {
    try socket.bind(to: address)
  }

  public func send(
    _ message: STUNMessage,
    to address: SocketAddress? = nil,
    completion handler: STUNResponseHandler? = nil
  ) {
    async { [self] in
      if message.type.class == .indication {
        send(message, to: address ?? configuration.server)
        return
      }

      let transaction = Transaction(
        message: message,
        address: address ?? configuration.server,
        handler: handler,
        rto: configuration.rto,
        timeoutHandler: didTimeout(_:)
      )
      transaction.start(on: configuration.eventLoop)
      transactions[message.transactionId] = transaction
      send(transaction.message, to: transaction.address) { result in
        if case .failure(let error) = result {
          transaction.cancel()
          transaction.onError(error)
          transactions[transaction.message.transactionId] = nil
        }
      }
    }
  }

  public func close() {
    async { [self] in
      for transaction in transactions.values {
        logger.trace("Transaction canceled", metadata: ["transactionId": "\(transaction.message.transactionId)"])
        transaction.cancel()
        transaction.onError(STUNError.canceled)
      }
      transactions.removeAll()
      socket.close()
    }
  }
}

// MARK: - Internal

extension STUNClient {

  internal func async(_ handler: @escaping Handler<Void>) {
    configuration.eventLoop.execute(handler)
  }

  internal func send(
    _ message: STUNMessage,
    to address: SocketAddress,
    completion handler: ResultHandler<Void>? = nil
  ) {
    message.withUnsafeBytes {
      socket.send($0, to: address) { result in
        switch result {
        case .success:
          logger.trace("Send \(message)", metadata: ["transactionId": "\(message.transactionId)"])
        case .failure(let error):
          logger.error("Send failed: \(error)", metadata: ["transactionId": "\(message.transactionId)"])
        }
        handler?(result)
      }
    }
  }

  internal func didReceiveMessage(_ message: STUNMessage) {
    logger.trace("Receive \(message)", metadata: ["transactionId": "\(message.transactionId)"])
    if message.type.class == .indication {
      configuration.indicationHandler?(message)
      return
    }

    guard let transaction = transactions[message.transactionId] else {
      logger.warning("Transaction not found", metadata: ["transactionId": "\(message.transactionId)"])
      return
    }

    transaction.cancel()
    transaction.onSuccess(message)
    transactions[message.transactionId] = nil
  }

  internal func didTimeout(_ transaction: Transaction) {
    transaction.attemptCount += 1
    guard transaction.attemptCount <= configuration.maxAttemptCount else {
      logger.error("Transaction timeout", metadata: ["transactionId": "\(transaction.message.transactionId)"])
      transaction.cancel()
      transaction.onError(STUNError.timeout)
      transactions[transaction.message.transactionId] = nil
      return
    }

    transaction.start(on: configuration.eventLoop)
    send(transaction.message, to: transaction.address) { [self] result in
      if case .failure(let error) = result {
        transaction.cancel()
        transaction.onError(error)
        transactions[transaction.message.transactionId] = nil
      }
    }
  }
}

// MARK: - STUNClient + UDPSocketDelegate

extension STUNClient: UDPSocketDelegate {

  public func socket(_ socket: UDPSocket, didReceive data: UnsafeRawBufferPointer, peerAddress address: SocketAddress) {
    do {
      didReceiveMessage(try STUNMessage(bytes: Array(data)))
    } catch {
      logger.error("Receive invalid STUN packet: \(error)")
    }
  }

  public func socket(_ socket: UDPSocket, didCloseWith error: Error?) {
    logger.trace("Client has been closed")
  }
}

// MARK: - STUNClient.Configuration

extension STUNClient {
  public struct Configuration {
    public var eventLoop: EventLoop
    public var server: SocketAddress
    // RFC 5389 says SHOULD be 500ms.
    // For years, this was 100ms, but for networks that
    // experience moments of high RTT (such as 2G networks), this doesn't
    // work well.
    public var rto: Duration
    public var indicationHandler: STUNIndicationHandler?
    // The timeout doubles each retransmission, up to this many times
    // RFC 5389 says SHOULD retransmit 7 times.
    internal var maxAttemptCount = 7

    public init(
      eventLoop: EventLoop = .default,
      server: SocketAddress,
      rto: Duration = .milliseconds(250),
      indicationHandler: STUNIndicationHandler? = nil
    ) {
      self.eventLoop = eventLoop
      self.server = server
      self.rto = rto
      self.indicationHandler = indicationHandler
    }
  }
}
