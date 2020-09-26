//
//  XCTestManifests.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(SocketAddressTests.allTests),
    testCase(MessageTests.allTests),
    testCase(AttributeTests.allTests),
    testCase(RFC5769Tests.allTests),
    testCase(IPAddressTests.allTests),
  ]
}
#endif
