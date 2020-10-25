//
//  NATBehaviorDiscovery.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/24.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN
import Network
import Core
import Dispatch

/// [NAT Behavior Discovery Using Session Traversal Utilities for NAT (STUN)](https://tools.ietf.org/html/rfc5780)
public final class NATBehaviorDiscovery {
  internal var localAddress: SocketAddress
  internal var transactions: [STUNTransactionId: Transaction]
  internal var serverAddress: SocketAddress
  internal var socket: UDPSocket
  internal var queue: DispatchQueue
  internal var thread: Thread!

  public init(server: String) throws {
    guard let address = NetworkInterface.all.first(where: { !$0.address.ip.isLoopback && $0.address.isIPv4 })?.address else {
      throw NATBehaviorDiscoveryError.invalidLocalAddress
    }
    guard let (scheme, host, port) = parseURI(server), scheme == "stun" else {
      throw NATBehaviorDiscoveryError.invalidServer
    }

    self.localAddress = address
    self.serverAddress = SocketAddress(ip: host, port: port ?? .stun)
    self.transactions = [:]
    self.socket = try UDPSocket.bind(to: localAddress)
    self.queue = DispatchQueue(label: "NATBehaviorDiscovery")
    self.thread = Thread { [unowned self] in loop() }
    self.thread.start()
  }

  /// Determining NAT mapping hehavior.
  ///
  /// https://tools.ietf.org/html/rfc5780#section-4.3
  public func discoverNATMappingBehavior(completion: @escaping (Result<NATBehavior, Error>) -> Void) {
    logger.debug("Running mapping behavior test I. Send binding request")
    send(STUNMessage(type: .bindingRequest), to: serverAddress) { [self] result in
      switch result {
      case .success(let message):
        guard let address1 = message.attribute(for: .xorMappedAddress)?.value.address else {
          completion(.failure(NATBehaviorDiscoveryError.attributeNotFound(.xorMappedAddress)))
          return
        }

        if address1 == socket.localAddress {
          completion(.success(.endpointIndependent))
          return
        }

        guard let otherAddress = message.attribute(for: .otherAddress)?.value.address else {
          completion(.failure(NATBehaviorDiscoveryError.attributeNotFound(.otherAddress)))
          return
        }

        logger.debug("Running mapping behavior test II. Send binding request to alternate address but primary port")
        send(STUNMessage(type: .bindingRequest), to: SocketAddress(ip: otherAddress.ip, port: serverAddress.port)) { [self] result in
          switch result {
          case .success(let message):
            guard let address2 = message.attribute(for: .xorMappedAddress)?.value.address else {
              completion(.failure(NATBehaviorDiscoveryError.attributeNotFound(.xorMappedAddress)))
              return
            }

            if address1 == address2 {
              completion(.success(.endpointIndependent))
              return
            }

            logger.debug("Running mapping behavior test III. Send binding request to alternate address")
            send(STUNMessage(type: .bindingRequest), to: otherAddress) { result in
              switch result {
              case .success(let message):
                guard let address3 = message.attribute(for: .xorMappedAddress)?.value.address else {
                  completion(.failure(NATBehaviorDiscoveryError.attributeNotFound(.xorMappedAddress)))
                  return
                }

                if address2 == address3 {
                  completion(.success(.addressDependent))
                } else {
                  completion(.success(.addressAndPortDependent))
                }
              case .failure:
                completion(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
              }
            }
          case .failure:
            completion(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
          }
        }
      case .failure:
        completion(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
      }
    }
  }

  /// Determining NAT filtering behavior.
  ///
  /// https://tools.ietf.org/html/rfc5780#section-4.4
  public func discoverNATFilteringBehavior(completion: @escaping (Result<NATBehavior, Error>) -> Void) {
    logger.debug("Running filtering behavior test I. Send binding request")
    send(STUNMessage(type: .bindingRequest), to: serverAddress) { [self] result in
      switch result {
      case .success(let message):
        guard message.attribute(for: .otherAddress) != nil else {
          completion(.failure(NATBehaviorDiscoveryError.attributeNotFound(.otherAddress)))
          return
        }

        logger.debug("Running filtering behavior test II. Send binding request with change ip and change port flag")
        var message = STUNMessage(type: .bindingRequest)
        message.append(.init(type: .changeRequest, value: .uint32(0x06000000)))
        send(message, to: serverAddress) { [self] result in
          switch result {
          case .success:
            completion(.success(.endpointIndependent))
          case .failure:
            logger.debug("Running filtering behavior test III. Send binding request with change port flag")
            var message = STUNMessage(type: .bindingRequest)
            message.append(.init(type: .changeRequest, value: .uint32(0x02000000)))
            send(message, to: serverAddress) { result in
              switch result {
              case .success:
                completion(.success(.addressDependent))
              case .failure:
                completion(.success(.addressAndPortDependent))
              }
            }
          }
        }
      case .failure:
        completion(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
      }
    }
  }
}

extension NATBehaviorDiscovery {

  internal func send(_ message: STUNMessage, to address: SocketAddress, completion: @escaping STUNRequestHandler) {
    queue.async { [self] in
      let transaction = Transaction(
        id: message.transactionId,
        raw: message.withUnsafeBytes(Array.init),
        destinationAddress: address,
        handler: completion,
        rto: .milliseconds(250),
        timeoutHandler: didTimeout(_:)
      )
      do {
        logger.trace("Send request: \(message.type) - \(message.transactionId)")
        try transaction.start(socket: socket, queue: queue)
        transactions[message.transactionId] = transaction
      } catch {
        logger.trace("Failed to send request: \(message.type) - \(message.transactionId) - \(error)")
        transaction.handler?(.failure(error))
      }
    }
  }

  internal func close() {
    queue.async { [self] in
      do {
        try socket.close()
      } catch {
        logger.error("\(error)")
      }
      thread.join()
    }
  }

  internal func didReceiveMessage(_ message: STUNMessage) {
    if let transaction = transactions[message.transactionId] {
      logger.trace("Receive response: \(message.type) - \(message.transactionId)")
      transaction.timeoutTask.cancel()
      transaction.handler?(.success(message))
      transactions[message.transactionId] = nil
    } else {
      logger.trace("Receive indication: \(message.type)")
    }
  }

  internal func didTimeout(_ transactionId: STUNTransactionId) {
    guard let transaction = transactions[transactionId] else {
      logger.warning("Invalid transaction: \(transactionId)")
      return
    }

    transaction.attemptCount += 1
    guard transaction.attemptCount <= 7 else {
      logger.trace("Request timeout: \(transactionId)")
      transaction.timeoutTask.cancel()
      transaction.handler?(.failure(STUNError.timeout))
      transactions[transaction.id] = nil
      return
    }

    do {
      logger.trace("Resend request: \(transactionId)")
      try transaction.start(socket: socket, queue: queue)
    } catch {
      logger.trace("Failed to resend request: \(transactionId)")
      transaction.timeoutTask.cancel()
      transaction.handler?(.failure(error))
      transactions[transaction.id] = nil
    }
  }
}

extension NATBehaviorDiscovery {

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
        logger.error("Invalid STUN packet: \(error)")
      } catch {
        logger.error("Receive failed: \(error)")
        break
      }
    }
  }
}
