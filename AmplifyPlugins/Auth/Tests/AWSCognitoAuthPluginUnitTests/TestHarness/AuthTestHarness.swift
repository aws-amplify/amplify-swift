//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import ClientRuntime

@testable import Amplify
@testable import AWSCognitoAuthPlugin


class AuthTestHarness {

    private let mockedCognitoHelper: MockedAuthCognitoPluginHelper
    private let testHarnessInput: AuthTestHarnessInput

    var apiUnderTest: AmplifyAPI {
        testHarnessInput.amplifyAPI
    }

    var plugin: AWSCognitoAuthPlugin {
        mockedCognitoHelper.createPlugin()
    }

    init(featureSpecification: FeatureSpecification) {

        let awsCognitoAuthConfig = featureSpecification.preConditions.amplifyConfiguration.auth?.plugins["awsCognitoAuthPlugin"]

        guard let jsonValueConfiguration = awsCognitoAuthConfig else {
            fatalError("Unable to get JSONValue for amplify config")
        }

        guard let authConfiguration = try? ConfigurationHelper
            .authConfiguration(jsonValueConfiguration) else {
            fatalError("Unable to create auth configuarion")
        }

        testHarnessInput = AuthTestHarnessInput.createInput(
            from: featureSpecification)

        mockedCognitoHelper = MockedAuthCognitoPluginHelper(
            authConfiguration: authConfiguration,
            initialAuthState: testHarnessInput.initialAuthState,
            mockIdentityProvider: testHarnessInput.getMockIdentityProvider(),
            mockIdentity: testHarnessInput.getMockIdentity())
    }

}
