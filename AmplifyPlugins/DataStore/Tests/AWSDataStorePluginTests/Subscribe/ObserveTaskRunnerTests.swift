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
        
        let started = expectation(description: "started")
        let mutationEventReceived = expectation(description: "mutationEvent received")
        mutationEventReceived.expectedFulfillmentCount = 5
        let mutationEventReceivedAfterCancel = expectation(description: "mutationEvent received")
        mutationEventReceivedAfterCancel.isInverted = true
        
        let task = Task {
            do {
                started.fulfill()
                for try await mutationEvent in sequence {
                    if mutationEvent.id == "id" {
                        mutationEventReceived.fulfill()
                    } else {
                        mutationEventReceivedAfterCancel.fulfill()
                    }
                }
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        }
        await fulfillment(of: [started], timeout: 10.0)
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
        await fulfillment(of: [mutationEventReceived], timeout: 1.0)
        
        task.cancel()
        mutationEvent = MutationEvent(id: "id2",
                                      modelId: "id",
                                      modelName: "name",
                                      json: "json",
                                      mutationType: .create)
        dataStorePublisher.send(input: mutationEvent)
        await fulfillment(of: [mutationEventReceivedAfterCancel], timeout: 1.0)
    }
}
