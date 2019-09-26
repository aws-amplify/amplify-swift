//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A context object passed in the HubPayload of all events dispatched to the Hub by an AmplifyOperation. This object
/// can be used to filter on a particular operation.
public struct AmplifyOperationContext<Request> {
    /// The id of the operation
    let operationId: UUID

    /// The Request used to instantiate the operation
    let request: Request
}
