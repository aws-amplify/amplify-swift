//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public protocol AuthDeleteUserTask:
    AmplifyAuthTaskRefactored where Success == Void,
                          Request == Void,
                          Failure == AuthError {
}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let deleteUserAPI = "Auth.deleteUserAPI"
}
