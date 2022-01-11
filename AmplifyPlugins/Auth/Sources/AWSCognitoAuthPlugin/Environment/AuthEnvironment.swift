//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import hierarchical_state_machine_swift

public struct AuthEnvironment: Environment {
    let userPoolConfigData: UserPoolConfigurationData?
    let identityPoolConfigData: IdentityPoolConfigurationData?
    let authenticationEnvironment: AuthenticationEnvironment?
    let authorizationEnvironment: AuthorizationEnvironment?
    let credentialStoreEnvironment: CredentialStoreEnvironment?
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
