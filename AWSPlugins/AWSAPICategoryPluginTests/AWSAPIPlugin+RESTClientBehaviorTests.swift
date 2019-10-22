//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin

class AWSAPIPluginRESTClientBehaviorTests: AWSAPICategoryPluginTestBase {

    func testPluginGet() {
        let operation = apiPlugin.get(apiName: "foo",
                                      path: "/path",
                                      listener: nil)

        XCTAssertNotNil(operation)

        guard operation is AWSAPIGetOperation else {
            XCTFail("operation could not be cast as AWSAPIGetOperation")
            return
        }

        XCTAssertNotNil(operation.request)
    }

}
