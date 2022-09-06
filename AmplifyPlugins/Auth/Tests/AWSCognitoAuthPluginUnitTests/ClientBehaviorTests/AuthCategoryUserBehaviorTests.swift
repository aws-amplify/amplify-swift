//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AuthCategoryUserBehaviorTests: XCTestCase {

    func testGetCurrentUserWhileSignedIn() async throws {
        let userId = "xyz987"
        let userName = "abc123"
        let tokens = AWSCognitoUserPoolTokens.testData(username: userName, sub: userId)
        let authState = Defaults.makeAuthState(tokens: tokens)
        let plugin = try createPlugin(authState: authState)

        let user = await plugin.getCurrentUser()

        XCTAssertNotNil(user)
        XCTAssertEqual(user?.userId, userId)
        XCTAssertEqual(user?.username, userName)
    }

    private func createPlugin(authState: AuthState,
                              file: StaticString = #filePath,
                              line: UInt = #line) throws -> AWSCognitoAuthPlugin {
        let plugin = AWSCognitoAuthPlugin()
        plugin.authStateMachine = Defaults.makeDefaultAuthStateMachine(initialState: authState)

        return plugin
    }
}
