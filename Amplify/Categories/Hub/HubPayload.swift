//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct HubPayload {
    public let event: String
    public let data: Codable?
    public let message: String?

    public init(event: String, data: Codable? = nil, message: String? = nil) {
        self.event = event
        self.data = data
        self.message = message
    }
}
