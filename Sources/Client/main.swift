//
//  main.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUN
import Network
import Core
import Logging
import Foundation

// https://www.voip-info.org/stun/
func main() throws {
  let config = STUNClient.Configuration { message in
    print(message)
  }
  let client = try STUNClient.connect(to: "stun:stun.l.google.com:19302", configuration: config)

  var request = STUNMessage(type: .bindingRequest)
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

  let indication = STUNMessage(type: .bindingIndication)
  client.send(indication)

  sleep(30)
  client.close()
}

do {
  logger.logLevel = .trace
  try main()
} catch {
  print(error)
}
