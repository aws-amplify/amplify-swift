//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSDataStorePlugin

final class ObserveTaskRunnerTests: XCTestCase {

    func testSuccess() async throws {
        let dataStorePublisher = DataStorePublisher()
        let runner = ObserveTaskRunner(publisher: dataStorePublisher.publisher)
        let sequence = runner.sequence
        
        let started = asyncExpectation(description: "started")
        let mutationEventReceived = asyncExpectation(description: "mutationEvent received",
                                                     expectedFulfillmentCount: 5)
        let mutationEventReceivedAfterCancel = asyncExpectation(description: "mutationEvent received", isInverted: true)
        
        let task = Task {
            do {
                await started.fulfill()
                for try await mutationEvent in sequence {
                    if mutationEvent.id == "id" {
                        await mutationEventReceived.fulfill()
                    } else {
                        await mutationEventReceivedAfterCancel.fulfill()
                    }
                }
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        }
        await waitForExpectations([started], timeout: 10.0)
        var mutationEvent = MutationEvent(id: "id",
                                          modelId: "id",
                                          modelName: "name",
                                          json: "json",
                                          mutationType: .create)
        dataStorePublisher.send(input: mutationEvent)
        dataStorePublisher.send(input: mutationEvent)
        dataStorePublisher.send(input: mutationEvent)
        dataStorePublisher.send(input: mutationEvent)
        dataStorePublisher.send(input: mutationEvent)
        await waitForExpectations([mutationEventReceived], timeout: 1.0)
        
        task.cancel()
        mutationEvent = MutationEvent(id: "id2",
                                      modelId: "id",
                                      modelName: "name",
                                      json: "json",
                                      mutationType: .create)
        dataStorePublisher.send(input: mutationEvent)
        await waitForExpectations([mutationEventReceivedAfterCancel], timeout: 1.0)
    }
}
