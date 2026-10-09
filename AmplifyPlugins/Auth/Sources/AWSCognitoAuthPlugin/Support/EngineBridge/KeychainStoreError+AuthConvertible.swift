//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Foundation
import InternalAWSCognitoAuth

// The public type's conversion, kept for callers that still hold one. The engine throws
// `EngineCredentialStoreError`; this goes through it, so the mapping table exists once
// (`EngineCredentialStoreError.engineError`). The bridge is lossless both ways (`KeychainStoreError+Engine.swift`),
// and `EngineCredentialStoreErrorTests` checks that both give the same `AuthError`.
extension KeychainStoreError: EngineAuthErrorConvertible {

    package var engineError: EngineAuthError {
        EngineCredentialStoreError(self).engineError
    }
}
