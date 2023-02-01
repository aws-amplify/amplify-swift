//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request for delete user
public struct AuthDeleteUserRequest: AmplifyOperationRequest {

    /// Options is unused for AuthDeleteUserRequest. It is included for conformance
    /// with the AmplifyOperationRequest protocol.
    public var options = Options()

    public init() {}
}

public extension AuthDeleteUserRequest {
    struct Options {}
}
