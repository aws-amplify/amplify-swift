//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol UserPoolEnvironment: Environment {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    var userPoolConfiguration: UserPoolConfigurationData { get }
    var cognitoUserPoolFactory: CognitoUserPoolFactory { get }
}

struct BasicUserPoolEnvironment: UserPoolEnvironment {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    let userPoolConfiguration: UserPoolConfigurationData
    let cognitoUserPoolFactory: CognitoUserPoolFactory
}

extension AuthEnvironment: UserPoolEnvironment {
    var userPoolConfiguration: UserPoolConfigurationData {
        userPoolEnvironment.userPoolConfiguration
    }

    var cognitoUserPoolFactory: CognitoUserPoolFactory {
        userPoolEnvironment.cognitoUserPoolFactory
    }
}
