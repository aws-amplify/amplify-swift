//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

extension PutEventsInput: AmplifyStringConvertible {}

extension PutEventsOutputResponse: AmplifyStringConvertible {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case eventsResponse = "EventsResponse"
    }
    
    public func encode(to encoder: Encoder) throws {
        var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
        if let eventsResponse = self.eventsResponse {
            try encodeContainer.encode(eventsResponse, forKey: .eventsResponse)
        }
    }
}

extension UpdateEndpointInput: AmplifyStringConvertible {}

extension UpdateEndpointOutputResponse: AmplifyStringConvertible {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case messageBody = "MessageBody"
    }

    public func encode(to encoder: Encoder) throws {
        var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
        if let messageBody = self.messageBody {
            try encodeContainer.encode(messageBody, forKey: .messageBody)
        }
    }
}
