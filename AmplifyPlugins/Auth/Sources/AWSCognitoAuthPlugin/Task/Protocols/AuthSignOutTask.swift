//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify

protocol AuthSignOutTask: AmplifyAuthTaskNonThrowing where Request == AuthSignOutRequest, Success == AuthSignOutResult { }

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let signOutAPI = "Auth.signOutAPI"
}
