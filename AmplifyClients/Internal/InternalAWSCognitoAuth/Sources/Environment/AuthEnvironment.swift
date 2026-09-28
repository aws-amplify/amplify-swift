//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct AuthEnvironment: Environment, LoggerProvider {
    package let configuration: AuthConfiguration
    package let userPoolConfigData: UserPoolConfigurationData?
    package let identityPoolConfigData: IdentityPoolConfigurationData?
    package let authenticationEnvironment: AuthenticationEnvironment?
    package let authorizationEnvironment: AuthorizationEnvironment?
    package let credentialsClient: CredentialStoreStateBehavior
    package let logger: any EngineScopedLogger
    /// How a WebAuthn sign-in's assertion runs. Empty, the plugin's path, unless the caller fills it
    /// (`AmplifyCognitoClient`).
    package let webAuthnSignInCeremony: WebAuthnSignInCeremonySlot

    package init(
        configuration: AuthConfiguration,
        userPoolConfigData: UserPoolConfigurationData?,
        identityPoolConfigData: IdentityPoolConfigurationData?,
        authenticationEnvironment: AuthenticationEnvironment?,
        authorizationEnvironment: AuthorizationEnvironment?,
        credentialsClient: CredentialStoreStateBehavior,
        logger: any EngineScopedLogger,
        webAuthnSignInCeremony: WebAuthnSignInCeremonySlot = WebAuthnSignInCeremonySlot()
    ) {
        self.configuration = configuration
        self.userPoolConfigData = userPoolConfigData
        self.identityPoolConfigData = identityPoolConfigData
        self.authenticationEnvironment = authenticationEnvironment
        self.authorizationEnvironment = authorizationEnvironment
        self.credentialsClient = credentialsClient
        self.logger = logger
        self.webAuthnSignInCeremony = webAuthnSignInCeremony
    }
}

extension AuthEnvironment: AuthenticationEnvironment {

    package var hostedUIEnvironment: HostedUIEnvironment? {
        guard let environment = authenticationEnvironment else {
            fatalError("Could not find authentication environment")
        }
        return environment.hostedUIEnvironment
    }

    package var userPoolEnvironment: UserPoolEnvironment {
        guard let authNEnv = authenticationEnvironment else {
            fatalError("Could not find authentication environment")
        }
        return authNEnv.userPoolEnvironment
    }

    package var srpSignInEnvironment: SRPSignInEnvironment {
        guard let authNEnv = authenticationEnvironment else {
            fatalError("Could not find authentication environment")
        }
        return authNEnv.srpSignInEnvironment
    }
}

/// An environment that carries its own logger.
///
/// Log sites with an environment in scope log through it, never through the global router, so two
/// environments with different loggers route independently of which was created first.
package protocol LoggerProvider {

    var logger: any EngineScopedLogger { get }
}
