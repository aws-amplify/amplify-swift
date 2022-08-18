//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(AuthenticationServices)
import Foundation

open class AuthWebUISignInTask: AmplifyAuthTask<AuthWebUISignInRequest, AuthSignInResult, AuthError> { }

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let webUISignInAPI = "Auth.webUISignInAPI"
}
#endif
