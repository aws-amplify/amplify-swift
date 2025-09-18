//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol AuthAutoSignInTask: AmplifyAuthTask where Request == AuthAutoSignInRequest, Success == AuthSignInResult, Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let autoSignInAPI = "Auth.autoSignInAPI"
}
