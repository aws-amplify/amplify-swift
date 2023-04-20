//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//#if !os(watchOS)
import Foundation
import Amplify

protocol AuthWebUISignInTask: AmplifyAuthTask where Request == AuthWebUISignInRequest, Success == AuthSignInResult, Failure == AuthError { }

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let webUISignInAPI = "Auth.webUISignInAPI"
}
//#endif
