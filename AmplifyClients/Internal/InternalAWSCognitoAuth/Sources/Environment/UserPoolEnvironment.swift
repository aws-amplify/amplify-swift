//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package protocol UserPoolEnvironment: Environment {

    typealias CognitoUserPoolFactory = @Sendable () throws -> CognitoUserPoolBehavior

    typealias CognitoUserPoolASFFactory = @Sendable () -> AdvancedSecurityBehavior

    typealias CognitoUserPoolAnalyticsHandlerFactory = @Sendable () -> UserPoolAnalyticsBehavior

    var userPoolConfiguration: UserPoolConfigurationData { get }
    var cognitoUserPoolFactory: CognitoUserPoolFactory { get }
    var cognitoUserPoolASFFactory: CognitoUserPoolASFFactory { get }
    var cognitoUserPoolAnalyticsHandlerFactory: CognitoUserPoolAnalyticsHandlerFactory { get }
}

package struct BasicUserPoolEnvironment: UserPoolEnvironment {
    package let userPoolConfiguration: UserPoolConfigurationData
    package let cognitoUserPoolFactory: CognitoUserPoolFactory
    package let cognitoUserPoolASFFactory: CognitoUserPoolASFFactory
    package let cognitoUserPoolAnalyticsHandlerFactory: CognitoUserPoolAnalyticsHandlerFactory

    package init(
        userPoolConfiguration: UserPoolConfigurationData,
        cognitoUserPoolFactory: @escaping CognitoUserPoolFactory,
        cognitoUserPoolASFFactory: @escaping CognitoUserPoolASFFactory,
        cognitoUserPoolAnalyticsHandlerFactory: @escaping CognitoUserPoolAnalyticsHandlerFactory
    ) {
        self.userPoolConfiguration = userPoolConfiguration
        self.cognitoUserPoolFactory = cognitoUserPoolFactory
        self.cognitoUserPoolASFFactory = cognitoUserPoolASFFactory
        self.cognitoUserPoolAnalyticsHandlerFactory = cognitoUserPoolAnalyticsHandlerFactory
    }
}

extension AuthEnvironment: UserPoolEnvironment {
    package var userPoolConfiguration: UserPoolConfigurationData {
        userPoolEnvironment.userPoolConfiguration
    }

    package var cognitoUserPoolFactory: CognitoUserPoolFactory {
        userPoolEnvironment.cognitoUserPoolFactory
    }

    package var cognitoUserPoolASFFactory: CognitoUserPoolASFFactory {
        userPoolEnvironment.cognitoUserPoolASFFactory
    }

    package var cognitoUserPoolAnalyticsHandlerFactory: CognitoUserPoolAnalyticsHandlerFactory {
        userPoolEnvironment.cognitoUserPoolAnalyticsHandlerFactory
    }
}
