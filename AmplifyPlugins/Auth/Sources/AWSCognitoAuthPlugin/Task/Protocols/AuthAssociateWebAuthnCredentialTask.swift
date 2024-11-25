//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import Foundation

protocol AuthAssociateWebAuthnCredentialTask: AmplifyAuthTask where
    Request == AuthAssociateWebAuthnCredentialRequest,
    Success == Void,
    Failure == AuthError {        
}

public extension HubPayload.EventName.Auth {
    static let associateWebAuthnCredentialAPI = "Auth.associateWebAuthnCredentialAPI"
}
#endif
