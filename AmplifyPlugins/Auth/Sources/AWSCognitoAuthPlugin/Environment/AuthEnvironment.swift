//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias CredentialStoreClientFactory = () -> CredentialStoreStateBehaviour

struct AuthEnvironment: Environment, LoggerProvider {
    let configuration: AuthConfiguration
    let userPoolConfigData: UserPoolConfigurationData?
    let identityPoolConfigData: IdentityPoolConfigurationData?
    let authenticationEnvironment: AuthenticationEnvironment?
    let authorizationEnvironment: AuthorizationEnvironment?
    let credentialStoreClientFactory: CredentialStoreClientFactory
    let logger: Logger
}

extension AuthEnvironment: AuthenticationEnvironment {

    var hostedUIEnvironment: HostedUIEnvironment? {
        guard let environment = authenticationEnvironment else {
            fatalError("Could not find authentication environment")
        }
        return environment.hostedUIEnvironment
    }

    var userPoolEnvironment: UserPoolEnvironment {
        guard let authNEnv = authenticationEnvironment else {
            fatalError("Could not find authentication environment")
        }
        return authNEnv.userPoolEnvironment
    }

    var srpSignInEnvironment: SRPSignInEnvironment {
        guard let authNEnv = authenticationEnvironment else {
            fatalError("Could not find authentication environment")
        }
        return authNEnv.srpSignInEnvironment
    }
}

protocol LoggerProvider {

    var logger: Logger { get }
}
