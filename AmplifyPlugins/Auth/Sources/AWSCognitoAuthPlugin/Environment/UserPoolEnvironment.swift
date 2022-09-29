//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol UserPoolEnvironment: Environment {

    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    typealias CognitoUserPoolASFFactory = () -> AdvancedSecurityBehavior

    typealias CognitoUserPoolAnalyticsHandlerFactory = () -> UserPoolAnalyticsBehavior

    var userPoolConfiguration: UserPoolConfigurationData { get }
    var cognitoUserPoolFactory: CognitoUserPoolFactory { get }
    var cognitoUserPoolASFFactory: CognitoUserPoolASFFactory { get }
    var cognitoUserPoolAnalyticsHandlerFactory: CognitoUserPoolAnalyticsHandlerFactory { get }
}

struct BasicUserPoolEnvironment: UserPoolEnvironment {
    let userPoolConfiguration: UserPoolConfigurationData
    let cognitoUserPoolFactory: CognitoUserPoolFactory
    let cognitoUserPoolASFFactory: CognitoUserPoolASFFactory
    let cognitoUserPoolAnalyticsHandlerFactory: CognitoUserPoolAnalyticsHandlerFactory
}

extension AuthEnvironment: UserPoolEnvironment {
    var userPoolConfiguration: UserPoolConfigurationData {
        userPoolEnvironment.userPoolConfiguration
    }

    var cognitoUserPoolFactory: CognitoUserPoolFactory {
        userPoolEnvironment.cognitoUserPoolFactory
    }

    var cognitoUserPoolASFFactory: CognitoUserPoolASFFactory {
        userPoolEnvironment.cognitoUserPoolASFFactory
    }

    var cognitoUserPoolAnalyticsHandlerFactory: CognitoUserPoolAnalyticsHandlerFactory {
        userPoolEnvironment.cognitoUserPoolAnalyticsHandlerFactory
    }
}
