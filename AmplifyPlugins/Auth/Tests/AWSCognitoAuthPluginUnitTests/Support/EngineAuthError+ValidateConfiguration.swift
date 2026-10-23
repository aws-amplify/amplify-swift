//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import InternalAWSCognitoAuth

extension EngineAuthError {
    /// `AuthError.validateConfigurationError` for the engine's own error. `EndpointResolving`'s validation
    /// steps throw `EngineAuthError`; `ConfigurationHelper` rethrows it as `AuthError`, which the
    /// configuration tests keep checking with `AuthError.validateConfigurationError`.
    static func validateConfigurationError(_ error: Error) {
        guard case .configuration = (error as? EngineAuthError) else {
            return XCTFail("Expected error EngineAuthError.configuration")
        }
    }
}
