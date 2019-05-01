//
//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class HubDefaultPluginDispatchTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    public func testCanDispatchOnCoreChannel() throws {
        XCTFail("Not yet implemented")
//        let configuration = BasicAmplifyConfiguration()
//        try Amplify.configure(configuration)
//
//        let payload = BasicHubPayload()
//        let channel = HubChannel.core
//
//        // If this method completes without a preconditionFailure, then the test passes :)
//        Amplify.Hub.dispatch(to: channel, payload: payload)
    }
}
