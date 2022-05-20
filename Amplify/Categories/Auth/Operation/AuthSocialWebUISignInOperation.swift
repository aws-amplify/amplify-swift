//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(AuthenticationServices)
import Foundation

public protocol AuthSocialWebUISignInOperation: AmplifyOperation<
    AuthWebUISignInRequest,
    AuthSignInResult,
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let socialWebUISignInAPI = "Auth.socialWebUISignInAPI"
}
#endif
