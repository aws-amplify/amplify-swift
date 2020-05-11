//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSAuthPlugin

class AWSAuthBaseTest: XCTestCase {

    let networkTimeout = TimeInterval(180) // 180 seconds to wait before network timeouts

     func initializeAmplify() {

        do {
            let configuration = try AuthConfigurationHelper.amplifyConfiguration()
            let authPlugin = AWSAuthPlugin()
            try Amplify.add(plugin: authPlugin)
            try Amplify.configure(configuration)
            print("Amplify configured with auth plugin")
        } catch {
            print(error)
            XCTFail("Failed to initialize Amplify with \(error)")
        }
    }
}
