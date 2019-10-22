//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginTestBase: XCTestCase {

    var apiPlugin: AWSAPICategoryPlugin!

    override func setUp() {
        apiPlugin = AWSAPICategoryPlugin()
    }

}
