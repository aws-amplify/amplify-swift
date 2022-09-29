//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AuthGetCurrentUserTests: XCTestCase {

    func testGetCurrentUserWhileSignedIn() async throws {
        let userId = "xyz987"
        let userName = "abc123"
        let tokens = AWSCognitoUserPoolTokens.testData(username: userName, sub: userId)
        let authState = Defaults.makeAuthState(tokens: tokens)
        let plugin = try createPlugin(authState: authState)

        let user = try! await plugin.getCurrentUser()

        XCTAssertEqual(user.userId, userId)
        XCTAssertEqual(user.username, userName)
    }

    func testGetCurrentUserWhileSignedOut() async throws {

        let authState = AuthState.configured(.signedOut(.testData), .notConfigured)
        let plugin = try createPlugin(authState: authState)

        do {
            _ = try await plugin.getCurrentUser()
            XCTFail("Should throw AuthError.signedOut")
        }
        catch AuthError.signedOut { }
        catch {
            XCTFail("Should throw AuthError.signedOut")
        }

    }

    func testGetCurrentUserWhileNotConfigured() async throws {

        let authState = AuthState.configured(.notConfigured, .notConfigured)
        let plugin = try createPlugin(authState: authState)

        do {
            _ = try await plugin.getCurrentUser()
            XCTFail("Should throw AuthError.configuration")
        }
        catch AuthError.configuration { }
        catch {
            XCTFail("Should throw AuthError.configuration")
        }

    }

    func testGetCurrentUserWithInvalidState() async throws {

        let authState = AuthState.configured(.signingIn(.notStarted), .notConfigured)
        let plugin = try createPlugin(authState: authState)

        do {
            _ = try await plugin.getCurrentUser()
            XCTFail("Should throw AuthError.invalidState")
        }
        catch AuthError.invalidState { }
        catch {
            XCTFail("Should throw AuthError.invalidState")
        }

    }



    private func createPlugin(authState: AuthState,
                              file: StaticString = #filePath,
                              line: UInt = #line) throws -> AWSCognitoAuthPlugin {
        let plugin = AWSCognitoAuthPlugin()
        plugin.authStateMachine = Defaults.makeDefaultAuthStateMachine(initialState: authState)

        return plugin
    }
}
