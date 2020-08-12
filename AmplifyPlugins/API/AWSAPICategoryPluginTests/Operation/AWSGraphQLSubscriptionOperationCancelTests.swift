//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
class AWSGraphQLSubscriptionOperationCancelTests: AWSAPICategoryPluginTestBase {

    func testCancelSendsCompletion() {
        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let receivedCompletion = expectation(description: "Received completion")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true

        let valueListener: GraphQLSubscriptionOperation<JSONValue>.InProcessListener = { _ in
            receivedValue.fulfill()
        }

        let completionListener: GraphQLSubscriptionOperation<JSONValue>.ResultListener = { result in
            switch result {
            case .failure:
                receivedFailure.fulfill()
            case .success:
                receivedCompletion.fulfill()
            }
        }

        let operation = apiPlugin.subscribe(
            request: request,
            valueListener: valueListener,
            completionListener: completionListener
        )

        operation.cancel()

        XCTAssert(operation.isCancelled)

        waitForExpectations(timeout: 0.05)
    }

}
