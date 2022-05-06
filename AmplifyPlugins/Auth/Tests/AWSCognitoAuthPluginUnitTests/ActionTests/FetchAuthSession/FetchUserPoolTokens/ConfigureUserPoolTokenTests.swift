//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore

@testable import AWSCognitoAuthPlugin

class ConfigureUserPoolTokenTests: XCTestCase {

    func testUserPoolTokensNotPresent() {

        let expectation = expectation(description: "throwUserPoolTokensNotPresentError")

        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(cognitoTokensResult: .failure(AuthError.unknown("", nil)))
        let action = ConfigureUserPoolToken(cognitoSession: cognitoSessionInput)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchUserPoolTokensEvent else {
                    return
                }

                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.service(error: AuthError.unknown("", nil)))
                    expectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testValidUserPoolTokensNotExpiring() {

        let userPoolTokensValidExpectation = expectation(description: "userPoolTokensAreValid")
        let fetchIdentityIdExpectation = expectation(description: "fetchIdentity")

        let tokenData = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]

        let cognitoUserPoolTokensInput = AWSCognitoUserPoolTokens(idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                                                  accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                                                  refreshToken: "refreshToken",
                                                                  expiresIn: 121)

        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(cognitoTokensResult: .success(cognitoUserPoolTokensInput))

        let action = ConfigureUserPoolToken(cognitoSession: cognitoSessionInput)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                if let event = event as? FetchUserPoolTokensEvent,
                   case .fetched = event.eventType
                {
                    userPoolTokensValidExpectation.fulfill()
                } else if let event = event as? FetchAuthSessionEvent,
                          case let .fetchIdentity(cognitoSession) = event.eventType
                {
                    XCTAssertEqual(cognitoSession, cognitoSessionInput)
                    fetchIdentityIdExpectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testUserPoolTokensExpiring() {

        let expectation = expectation(description: "refreshUserPoolTokens")
        
        let tokenData = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 119).timeIntervalSince1970)
        ]

        let cognitoUserPoolTokensInput = AWSCognitoUserPoolTokens(idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                                                  accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                                                  refreshToken: "refreshToken",
                                                                  expiresIn: 119)

        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(cognitoTokensResult: .success(cognitoUserPoolTokensInput))

        let action = ConfigureUserPoolToken(cognitoSession: cognitoSessionInput)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchUserPoolTokensEvent else {
                    return
                }

                if case let .refresh(cognitoSession) = event.eventType {
                    XCTAssertEqual(cognitoSession, cognitoSessionInput)
                    expectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

}
