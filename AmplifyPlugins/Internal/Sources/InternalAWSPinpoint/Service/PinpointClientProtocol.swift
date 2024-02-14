//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

public protocol PinpointClientProtocol {

    func updateEndpoint(input: UpdateEndpointInput) async throws -> UpdateEndpointOutput

    func putEvents(input: PutEventsInput) async throws -> PutEventsOutput

}

extension PinpointClient: PinpointClientProtocol { }
