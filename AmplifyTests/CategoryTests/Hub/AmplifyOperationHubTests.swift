//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class AmplifyOperationHubTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// Given: An AmplifyOperation
    /// When: I invoke Hub.listen(to: operation)
    /// Then: I am notified of events for that operation, in the operation event listener format
    func testOperationOnEvent() {
        let request = StorageListRequest(options: StorageListRequest.Options())

        let operation = NonListeningStorageListOperation(request: request)

        let onEventWasInvoked = expectation(description: "onEvent was invoked")

        let onEvent: NonListeningStorageListOperation.EventHandler = { event in
            onEventWasInvoked.fulfill()
        }

        _ = Amplify.Hub.listen(to: operation, onEvent: onEvent)

        let event: NonListeningStorageListOperation.Event = .notInProcess
        operation.dispatch(event: event)

        waitForExpectations(timeout: 1.0)
    }
}

class NonListeningStorageListOperation: AmplifyOperation<StorageListRequest, Void, StorageListResult, StorageError>,
StorageListOperation {
    init(request: Request) {
        super.init(categoryType: .storage, request: request)
    }
}
