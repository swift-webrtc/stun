//
//  NATBehaviorDiscovery.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/24.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN
import AsyncIO

/// [NAT Behavior Discovery Using Session Traversal Utilities for NAT (STUN)](https://tools.ietf.org/html/rfc5780)
public final class NATBehaviorDiscovery {
  internal var server: SocketAddress
  internal var stun: STUNClient

  public init(eventLoop: EventLoop = .default, server: SocketAddress) {
    self.server = server
    self.stun = STUNClient(configuration: .init(eventLoop: eventLoop, server: server))
  }

  public func discover(completion handler: @escaping (Result<(NATBehavior, NATBehavior), Error>) -> Void) {
    guard let address = NetworkInterface.localAddress else {
      handler(.failure(NATBehaviorDiscoveryError.localAddressNotExist))
      return
    }

    do {
      try stun.bind(to: address)
    } catch {
      handler(.failure(error))
      stun.close()
      return
    }

    discoverNATMappingBehavior { [self] result in
      switch result {
      case .success(let mappingBehavior):
        discoverNATFilteringBehavior { result in
          switch result {
          case .success(let filteringBehavior):
            handler(.success((mappingBehavior, filteringBehavior)))
          case .failure(let error):
            handler(.failure(error))
          }
          stun.close()
        }
      case .failure(let error):
        handler(.failure(error))
        stun.close()
      }
    }
  }

  /// Determining NAT mapping hehavior.
  ///
  /// https://tools.ietf.org/html/rfc5780#section-4.3
  internal func discoverNATMappingBehavior(handler: @escaping (Result<NATBehavior, Error>) -> Void) {
    logger.debug("Running mapping behavior test I. Send binding request")
    stun.send(STUNMessage(type: .init(method: .binding, class: .request)), to: server) { [self] result in
      switch result {
      case .success(let message):
        guard let address1 = message.attributeValue(for: .xorMappedAddress, as: STUNXorAddress.self)?.address else {
          handler(.failure(NATBehaviorDiscoveryError.attributeNotFound(.xorMappedAddress)))
          return
        }

        if address1 == stun.localAddress {
          handler(.success(.endpointIndependent))
          return
        }

        guard let otherAddress = message.attributeValue(for: .otherAddress, as: STUNAddress.self) else {
          handler(.failure(NATBehaviorDiscoveryError.attributeNotFound(.otherAddress)))
          return
        }

        logger.debug("Running mapping behavior test II. Send binding request to alternate address but primary port")
        stun.send(STUNMessage(type: .init(method: .binding, class: .request)), to: SocketAddress(ip: otherAddress.ip, port: server.port)) { [self] result in
          switch result {
          case .success(let message):
            guard let address2 = message.attributeValue(for: .xorMappedAddress, as: STUNXorAddress.self)?.address else {
              handler(.failure(NATBehaviorDiscoveryError.attributeNotFound(.xorMappedAddress)))
              return
            }

            if address1 == address2 {
              handler(.success(.endpointIndependent))
              return
            }

            logger.debug("Running mapping behavior test III. Send binding request to alternate address")
            stun.send(STUNMessage(type: .init(method: .binding, class: .request)), to: otherAddress) { result in
              switch result {
              case .success(let message):
                guard let address3 = message.attributeValue(for: .xorMappedAddress, as: STUNXorAddress.self)?.address else {
                  handler(.failure(NATBehaviorDiscoveryError.attributeNotFound(.xorMappedAddress)))
                  return
                }

                if address2 == address3 {
                  handler(.success(.addressDependent))
                } else {
                  handler(.success(.addressAndPortDependent))
                }
              case .failure:
                handler(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
              }
            }
          case .failure:
            handler(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
          }
        }
      case .failure:
        handler(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
      }
    }
  }

  /// Determining NAT filtering behavior.
  ///
  /// https://tools.ietf.org/html/rfc5780#section-4.4
  internal func discoverNATFilteringBehavior(completion handler: @escaping (Result<NATBehavior, Error>) -> Void) {
    logger.debug("Running filtering behavior test I. Send binding request")
    stun.send(STUNMessage(type: .init(method: .binding, class: .request)), to: server) { [self] result in
      switch result {
      case .success(let message):
        guard message.attribute(for: .otherAddress) != nil else {
          handler(.failure(NATBehaviorDiscoveryError.attributeNotFound(.otherAddress)))
          return
        }

        logger.debug("Running filtering behavior test II. Send binding request with change ip and change port flag")
        var message = STUNMessage(type: .init(method: .binding, class: .request))
        message.appendAttribute(type: .changeRequest, value: 0x00000006 as UInt32)
        stun.send(message, to: server) { [self] result in
          switch result {
          case .success:
            handler(.success(.endpointIndependent))
          case .failure:
            logger.debug("Running filtering behavior test III. Send binding request with change port flag")
            var message = STUNMessage(type: .init(method: .binding, class: .request))
            message.appendAttribute(type: .changeRequest, value: 0x00000002 as UInt32)
            stun.send(message, to: server) { result in
              switch result {
              case .success:
                handler(.success(.addressDependent))
              case .failure:
                handler(.success(.addressAndPortDependent))
              }
            }
          }
        }
      case .failure:
        handler(.failure(NATBehaviorDiscoveryError.noUDPConnectivity))
      }
    }
  }
}
