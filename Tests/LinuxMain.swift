//
//  LinuxMain.swift
//  webrtc-stun
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import STUNTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += SocketAddressTests.allTests
tests += MessageTests.allTests
tests += AttributeTests.allTests
tests += RFC5769Tests.allTests
tests += IPAddressTests.allTests
XCTMain(tests)
