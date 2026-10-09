//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package protocol AuthorizationEnvironment: Environment {

    typealias CognitoIdentityFactory = @Sendable () throws -> CognitoIdentityBehavior
    var identityPoolConfiguration: IdentityPoolConfigurationData { get }
    var cognitoIdentityFactory: CognitoIdentityFactory { get }
    var eventIDFactory: EventIDFactory { get }

}

package struct BasicAuthorizationEnvironment: AuthorizationEnvironment {

    package typealias CognitoIdentityFactory = @Sendable () throws -> CognitoIdentityBehavior

    // Required
    package let identityPoolConfiguration: IdentityPoolConfigurationData
    package let cognitoIdentityFactory: CognitoIdentityFactory

    // Optional
    package let eventIDFactory: EventIDFactory

    package init(
        identityPoolConfiguration: IdentityPoolConfigurationData,
        cognitoIdentityFactory: @escaping CognitoIdentityFactory,
        eventIDFactory: @escaping EventIDFactory = UUIDFactory.factory
    ) {
        self.identityPoolConfiguration = identityPoolConfiguration
        self.cognitoIdentityFactory = cognitoIdentityFactory

        self.eventIDFactory = eventIDFactory
    }
}

extension AuthEnvironment: AuthorizationEnvironment {
    package var identityPoolConfiguration: IdentityPoolConfigurationData {
        guard let authorizationEnvironment else {
            fatalError("Could not find authorization environment")
        }
        return authorizationEnvironment.identityPoolConfiguration
    }

    package var cognitoIdentityFactory: CognitoIdentityFactory {
        guard let authorizationEnvironment else {
            fatalError("Could not find authorization environment")
        }
        return authorizationEnvironment.cognitoIdentityFactory
    }

}
