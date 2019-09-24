//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The payload of a Hub message
public struct HubPayload {

    /// The name, tag, or grouping of the HubPayload. Recommended to be a small string without spaces,
    /// such as `signIn` or `hang_up`.
    public let event: String

    /// A structure used to pass the source, or context, of the HubPayload. For HubPayloads that are
    /// generated from AmplifyOperations, this field will be the Operation's associated RequestContext.
    public let context: Any?

    /// A freeform structure used to pass objects or custom data. For HubPayloads that are generated from
    /// AmplifyOperations, this field will be the Operation's associated AsyncEvent.
    public let data: Any?

    public init(event: String,
                context: Any? = nil,
                data: Any? = nil) {
        self.event = event
        self.context = context
        self.data = data
    }
}
