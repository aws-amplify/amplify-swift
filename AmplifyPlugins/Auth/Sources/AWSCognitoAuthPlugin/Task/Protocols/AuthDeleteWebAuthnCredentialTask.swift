//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol AuthDeleteWebAuthnCredentialTask: AmplifyAuthTask where
    Request == AuthDeleteWebAuthnCredentialRequest,
    Success == Void,
    Failure == AuthError {
}

public extension HubPayload.EventName.Auth {
    static let deleteWebAuthnCredentialAPI = "Auth.deleteWebAuthnCredentialAPI"
}
