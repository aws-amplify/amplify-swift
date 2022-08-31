//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthFetchSessionTask: AmplifyAuthTask where Request == AuthFetchSessionRequest, Success == AuthSession, Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let fetchSessionAPI = "Auth.fetchSessionAPI"
}
