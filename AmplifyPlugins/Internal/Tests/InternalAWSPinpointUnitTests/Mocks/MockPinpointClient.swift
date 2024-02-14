//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation
import InternalAWSPinpoint

class MockPinpointClient: PinpointClientProtocol {

    var putEventsCount = 0
    var putEventsResult: Result<PutEventsOutput, Error> = .failure(CancellationError())
    var putEventsLastInput: PutEventsInput?
    func putEvents(input: PutEventsInput) async throws -> PutEventsOutput {
        putEventsCount += 1
        putEventsLastInput = input
        return try putEventsResult.get()
    }

    var updateEndpointCount = 0
    var updateEndpointResult: Result<UpdateEndpointOutput, Error>?
    func updateEndpoint(input: UpdateEndpointInput) async throws -> UpdateEndpointOutput {
        updateEndpointCount += 1
        guard let result = updateEndpointResult else {
            return UpdateEndpointOutput()
        }

        switch result {
        case .success(let output):
            return output
        case .failure(let error):
            throw error
        }
    }

}
