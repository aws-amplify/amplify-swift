//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

final class AWSCognitoAuthPluginTests: XCTestCase {

    var systemUnderTest: AWSCognitoAuthPlugin!
    var authorizationProvider: MockAuthorizationProviderBehavior!

    override func setUpWithError() throws {
        authorizationProvider = MockAuthorizationProviderBehavior()
        systemUnderTest = AWSCognitoAuthPlugin()
        systemUnderTest.authorizationProvider = authorizationProvider
    }

    override func tearDownWithError() throws {
        systemUnderTest = nil
    }

    /// - Given: A plugin configured with an authorization provider
    /// - When: An invalidateCachedTemporaryCredentials message is sent to the plugin
    /// - Then: The message is propagated to the authorization provider
    func testInvalidateCachedTemporaryCredentials() throws {
        systemUnderTest.invalidateCachedTemporaryCredentials()
        XCTAssertEqual(authorizationProvider.interactions, [
            "invalidateCachedTemporaryCredentials()"
        ])
    }

}
