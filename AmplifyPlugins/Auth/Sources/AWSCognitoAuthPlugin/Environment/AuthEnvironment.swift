//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct AuthEnvironment: Environment {
    let configuration: AuthConfiguration
    let userPoolConfigData: UserPoolConfigurationData?
    let identityPoolConfigData: IdentityPoolConfigurationData?
    let authenticationEnvironment: AuthenticationEnvironment?
    let authorizationEnvironment: AuthorizationEnvironment?

    let logger: Logger
}

extension AuthEnvironment: AuthenticationEnvironment {

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

extension AuthEnvironment: AuthorizationEnvironment {
    var identityPoolConfiguration: IdentityPoolConfigurationData {
        guard let authZEnv = authorizationEnvironment else {
            fatalError("Could not find authorization environment")
        }
        return authZEnv.identityPoolConfiguration
    }

    var cognitoIdentityFactory: CognitoIdentityFactory {
        guard let authZEnv = authorizationEnvironment else {
            fatalError("Could not find authorization environment")
        }
        return authZEnv.cognitoIdentityFactory
    }
}
