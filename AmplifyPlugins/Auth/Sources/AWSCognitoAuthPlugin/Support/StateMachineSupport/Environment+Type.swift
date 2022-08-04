//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Environment {

    func userPoolEnvironment() throws -> UserPoolEnvironment {
        guard let userPoolEnvironment  = self as? UserPoolEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthenticationError.configuration(message: message)
            throw authError
        }
        return userPoolEnvironment
    }

    func srpEnvironment() throws -> SRPAuthEnvironment {

        guard let environment = self as? SRPAuthEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            throw error
        }
        return environment
    }

    func authEnvironment() throws -> AuthEnvironment {

        guard let environment = self as? AuthEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            throw error
        }
        return environment
    }
}
