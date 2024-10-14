//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol AuthDeleteUserTask: AmplifyAuthTask where Request == Never, Success == Void, Failure == AuthError { }

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let deleteUserAPI = "Auth.deleteUserAPI"
}
