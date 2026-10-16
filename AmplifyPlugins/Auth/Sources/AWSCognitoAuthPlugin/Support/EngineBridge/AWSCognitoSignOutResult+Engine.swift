//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import InternalAWSCognitoAuth

// The public sign-out failure payloads, built from the engine's. The sign-out task uses
// these when it builds `AWSCognitoSignOutResult.partial`. Each field is copied, and the error goes through
// `AuthError(_:)`.

extension AWSCognitoRevokeTokenError {
    init(_ failure: EngineRevokeTokenFailure) {
        self.init(refreshToken: failure.refreshToken, error: AuthError(failure.error))
    }
}

extension AWSCognitoGlobalSignOutError {
    init(_ failure: EngineGlobalSignOutFailure) {
        self.init(accessToken: failure.accessToken, error: AuthError(failure.error))
    }
}

extension AWSCognitoHostedUIError {
    init(_ failure: EngineHostedUISignOutFailure) {
        self.init(error: AuthError(failure.error))
    }
}
