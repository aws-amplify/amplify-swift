//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginResetTests: AWSAPICategoryPluginTestBase {

    func testReset() {
        let completedInvoked = expectation(description: "onComplete is invoked")
        apiPlugin.reset {
            completedInvoked.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertNotNil(apiPlugin.mapper)
        XCTAssertEqual(apiPlugin.mapper.operations.count, 0)
        XCTAssertEqual(apiPlugin.mapper.tasks.count, 0)
        XCTAssertNil(apiPlugin.session)
        XCTAssertNil(apiPlugin.pluginConfig)
        XCTAssertNil(apiPlugin.authService)
        apiPlugin = nil
    }

    func testResetWithOperations() throws {
        let completedInvoked = expectation(description: "onComplete is invoked")
        let request = GraphQLOperationRequest(apiName: "apiName",
                                                 operationType: .mutation,
                                                 document: testDocument,
                                                 responseType: String.self,
                                                 options: GraphQLOperationRequest.Options())
        let operation = AWSGraphQLOperation(
            request: request,
            session: apiPlugin.session,
            mapper: apiPlugin.mapper,
            pluginConfig: pluginConfig) { _ in

        }

        operation.main()

        apiPlugin.reset {
            completedInvoked.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertNotNil(apiPlugin.mapper)
        XCTAssertEqual(apiPlugin.mapper.operations.count, 0)
        XCTAssertEqual(apiPlugin.mapper.tasks.count, 0)
        XCTAssertNil(apiPlugin.session)
        XCTAssertNil(apiPlugin.pluginConfig)
        XCTAssertNil(apiPlugin.authService)
        apiPlugin = nil
    }

}
