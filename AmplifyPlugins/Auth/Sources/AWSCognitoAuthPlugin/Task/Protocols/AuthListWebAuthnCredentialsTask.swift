//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol AuthListWebAuthnCredentialsTask: AmplifyAuthTask where
    Request == AuthListWebAuthnCredentialsRequest,
    Success == AuthListWebAuthnCredentialsResult,
    Failure == AuthError {
}

public extension HubPayload.EventName.Auth {
    static let listWebAuthnCredentialsAPI = "Auth.listWebAuthnCredentialsAPI"
}
