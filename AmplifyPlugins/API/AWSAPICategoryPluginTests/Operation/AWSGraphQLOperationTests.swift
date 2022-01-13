//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

@available(iOS 13.0, *)
class AWSGraphQLOperationTests: AWSAPICategoryPluginTestBase {

    /// Tests that upon completion, the operation is removed from the task mapper.
    func testOperationCleanup() {
        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let operation = apiPlugin.query(request: request, listener: nil)

        guard let operation = operation as? AWSGraphQLOperation else {
            XCTFail("Operation is not an AWSGraphQLOperation")
            return
        }

        let receivedCompletion = expectation(description: "Received completion")
        let sink = operation.resultPublisher.sink { _ in
            receivedCompletion.fulfill()
        } receiveValue: { _ in }
        defer { sink.cancel() }

        wait(for: [receivedCompletion], timeout: 1)
        let task = operation.mapper.task(for: operation)
        XCTAssertNil(task)
    }

}
