//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AuthorizationEnvironment: Environment {

    typealias CognitoIdentityFactory = () throws -> CognitoIdentityBehavior
    var identityPoolConfiguration: IdentityPoolConfigurationData { get }
    var cognitoIdentityFactory: CognitoIdentityFactory { get }
    var eventIDFactory: EventIDFactory { get }

}

struct BasicAuthorizationEnvironment: AuthorizationEnvironment {

    typealias CognitoIdentityFactory = () throws -> CognitoIdentityBehavior

    // Required
    let identityPoolConfiguration: IdentityPoolConfigurationData
    let cognitoIdentityFactory: CognitoIdentityFactory

    // Optional
    let eventIDFactory: EventIDFactory

    init(
        identityPoolConfiguration: IdentityPoolConfigurationData,
        cognitoIdentityFactory: @escaping CognitoIdentityFactory,
        eventIDFactory: @escaping EventIDFactory = UUIDFactory.factory
    ) {
        self.identityPoolConfiguration = identityPoolConfiguration
        self.cognitoIdentityFactory = cognitoIdentityFactory

        self.eventIDFactory = eventIDFactory
    }
}
