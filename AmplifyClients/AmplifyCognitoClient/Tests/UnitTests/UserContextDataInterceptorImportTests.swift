//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSCognitoIdentityProvider
import XCTest
@_spi(AmplifyExperimental) import AmplifyCognitoClient

/// What an app writes. This file imports `AmplifyCognitoClient` and not `AmplifyCognitoASF`, where
/// `CognitoUserContextData` lives, so it compiles only while the client re-exports it.
final class UserContextDataInterceptorImportTests: XCTestCase {

    /// Test that one import of the client adds the interceptor to a Cognito client's configuration
    ///
    /// - Given: A file that imports `AmplifyCognitoClient` with its SPI, and not `AmplifyCognitoASF`
    /// - When:
    ///    - it makes `CognitoUserContextData` and adds its interceptor provider to a configuration
    /// - Then:
    ///    - the configuration holds one more HTTP interceptor provider
    ///
    func testOneImportOfTheClientAddsTheInterceptor() throws {
        let contextData = CognitoUserContextData(userPoolId: "us-east-1_EXAMPLE", userPoolClientId: "1example23456789abcdefghij")
        var config = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(
            appID: "user-context-data-tests",
            awsRetryMode: .standard,
            ignoreConfiguredEndpointURLs: true,
            region: "us-east-1"
        )
        let before = config.httpInterceptorProviders.count

        config.addInterceptorProvider(contextData.interceptorProvider())

        XCTAssertEqual(config.httpInterceptorProviders.count, before + 1)
    }
}
