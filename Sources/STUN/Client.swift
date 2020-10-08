//
//  Client.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Network
import Core
import Dispatch

public typealias STUNRequestHandler = (Result<STUNMessage, Error>) -> Void
public typealias STUNIndicationHandler = (STUNMessage) -> Void

/// [RFC5389#section-7.2.1](https://tools.ietf.org/html/rfc5389#section-7.2.1)
public final class STUNClient {

  public static func connect(to server: String, configuration: Configuration) throws -> STUNClient {
    guard let (scheme, host, port) = parseURI(server), scheme == "stun" else {
      throw STUNError.invalidServer
    }

    let socket = try UDPSocket.connect(to: SocketAddress(ip: host, port: port ?? .stun))
    return STUNClient(socket: socket, configuration: configuration)
  }

  internal var configuration: Configuration
  internal var transactions: [STUNTransactionId: STUNTransaction]
  internal var socket: UDPSocket
  internal var queue: DispatchQueue
  internal var thread: Thread!

  internal init(socket: UDPSocket, configuration: Configuration) {
    self.configuration = configuration
    self.transactions = [:]
    self.socket = socket
    self.queue = DispatchQueue(label: "STUNClient")
    self.thread = Thread { [unowned self] in loop() }
    self.thread.start()
  }

  public func send(_ message: STUNMessage, completion: STUNRequestHandler? = nil) {
    queue.async { [self] in
      if message.type.isIndication {
        do {
          try message.withUnsafeBytes(socket.send(_:))
          logger.trace("Send indication: \(message.type)")
        } catch {
          logger.trace("Failed to send indication: \(message.type)")
        }
        return
      }

      let transaction = STUNTransaction(
        id: message.transactionId,
        raw: message.withUnsafeBytes(Array.init),
        handler: completion,
        rto: configuration.rto,
        timeoutHandler: didTimeout(_:)
      )
      do {
        try strat(transaction)
        transactions[message.transactionId] = transaction
        logger.trace("Send request: \(message.type) - \(message.transactionId)")
      } catch {
        transaction.handler?(.failure(error))
        logger.trace("Failed to send request: \(message.type) - \(message.transactionId) - \(error)")
      }
    }
  }

  public func close() {
    queue.async { [self] in
      do {
        try socket.close()
      } catch {
        logger.error("close: \(error)")
      }
      thread.join()
    }
  }

  internal func strat(_ transaction: STUNTransaction) throws {
    _ = try transaction.raw.withUnsafeBytes(socket.send(_:))
    transaction.start(on: queue)
  }

  internal func didTimeout(_ transactionId: STUNTransactionId) {
    guard let transaction = transactions[transactionId] else {
      logger.warning("Invalid transaction: \(transactionId)")
      return
    }

    transaction.attemptCount += 1
    guard transaction.attemptCount <= configuration.maxAttemptCount else {
      transaction.timeoutTask.cancel()
      transaction.handler?(.failure(STUNError.timeout))
      transactions[transaction.id] = nil
      logger.trace("Request timeout: \(transactionId)")
      return
    }

    do {
      try strat(transaction)
      logger.info("Resend request: \(transactionId)")
    } catch {
      transaction.timeoutTask.cancel()
      transaction.handler?(.failure(error))
      transactions[transaction.id] = nil
      logger.trace("Failed to resend request: \(transactionId)")
    }
  }
}

extension STUNClient {

  internal func didReceiveMessage(_ message: STUNMessage) {
    if let transaction = transactions[message.transactionId] {
      transaction.timeoutTask.cancel()
      transaction.handler?(.success(message))
      transactions[message.transactionId] = nil
      logger.trace("Receive response: \(message.type) - \(message.transactionId)")
    } else {
      configuration.indicationHandler?(message)
      logger.trace("Receive indication: \(message.type)")
    }
  }

  internal func loop() {
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
    buffer.initialize(repeating: 0, count: 1024)
    defer {
      buffer.deallocate()
    }

    while true {
      do {
        let count = try socket.recv(UnsafeMutableRawBufferPointer(start: buffer, count: 1024))
        let message = try STUNMessage(bytes: Array(UnsafeMutableBufferPointer(start: buffer, count: count)))
        queue.async { [self] in
          didReceiveMessage(message)
        }
      } catch let error as STUNError {
        logger.error("Receive invalid stun packet: \(error)")
      } catch {
        logger.error("Receive failed: \(error)")
        break
      }
    }
  }
}

// MARK: - STUNClient.Configuration

extension STUNClient {
  public struct Configuration {
    // RFC 5389 says SHOULD be 500ms.
    // For years, this was 100ms, but for networks that
    // experience moments of high RTT (such as 2G networks), this doesn't
    // work well.
    public var rto: Duration
    public var indicationHandler: STUNIndicationHandler?
    // The timeout doubles each retransmission, up to this many times
    // RFC 5389 says SHOULD retransmit 7 times.
    internal var maxAttemptCount = 7

    public init(rto: Duration = .milliseconds(250), indicationHandler: STUNIndicationHandler? = nil) {
      self.rto = rto
      self.indicationHandler = indicationHandler
    }
  }
}
