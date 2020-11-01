//
//  main.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN
import AsyncIO
import Core

// https://www.voip-info.org/stun/
func main() throws {
  let client = STUNClient(configuration: .init(server: SocketAddress("stun.l.google.com:19302")!) { message in
    print("Receive indication: \(message)")
  })
  do {
    try client.bind()
  } catch {
    print(error)
    client.close()
    return
  }

  var request = STUNMessage(type: .init(method: .binding, class: .request))
  request.appendAttribute(type: .software, value: "swift-webrtc")
  request.appendFingerprint()
  client.send(request) { result in
    switch result {
    case .success(let response):
      print("Send success: \(response)")
    case .failure(let error):
      print("Send failure: \(error)")
    }
  }

  let indication = STUNMessage(type: .init(method: .binding, class: .indication))
  client.send(indication)

  EventLoop.default.schedule(delay: .seconds(10)) { _ in
    client.close()
  }

  try EventLoop.default.run()
  try EventLoop.default.close()
}

do {
  LoggerConfiguration.default.logLevel = .trace
  try main()
} catch {
  print(error)
}
