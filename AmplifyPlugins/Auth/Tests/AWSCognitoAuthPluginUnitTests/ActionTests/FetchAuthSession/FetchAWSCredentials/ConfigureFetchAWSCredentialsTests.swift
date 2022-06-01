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

class ConfigureFetchAWSCredentialsTests: XCTestCase {

    func testIdentityIdNotPresent() {

        let expectation = expectation(description: "throwIdentityIdError")

        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(identityIdResult: .failure(AuthError.unknown("", nil)))
        let action = ConfigureFetchAWSCredentials(cognitoSession: cognitoSessionInput)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchAWSCredentialEvent else {
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

    func testWithValidIdentityAndCredentials() {

        let credentialValidExpectation = expectation(description: "awsCredentialsAreValid")
        let fetchedAuthSessionExpectation = expectation(description: "fetchedAuthSession")

        let awsCredentialsInput = AuthAWSCognitoCredentials(accessKey: "accessKey",
                                                            secretKey: "secretKey",
                                                            sessionKey: "sessionKey",
                                                            expiration: Date().addingTimeInterval(Double(11 * 60)))
        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(awsCredentialsResult: .success(awsCredentialsInput))
        let action = ConfigureFetchAWSCredentials(cognitoSession: cognitoSessionInput)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                if let event = event as? FetchAWSCredentialEvent,
                   case .fetched = event.eventType {
                    credentialValidExpectation.fulfill()
                } else if let event = event as? FetchAuthSessionEvent,
                          case .fetchedAuthSession = event.eventType {
                    fetchedAuthSessionExpectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testWithValidIdentityAndExpiringCredentials() {

        let expectation = expectation(description: "startFetchingAWSCredentials")

        let awsCredentialsInput = AuthAWSCognitoCredentials(accessKey: "accessKey",
                                                            secretKey: "secretKey",
                                                            sessionKey: "sessionKey",
                                                            expiration: Date().addingTimeInterval(Double(119)))
        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(awsCredentialsResult: .success(awsCredentialsInput))
        let action = ConfigureFetchAWSCredentials(cognitoSession: cognitoSessionInput)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchAWSCredentialEvent else {
                    return
                }

                if case let .fetch(cognitoSession) = event.eventType {
                    XCTAssertEqual(cognitoSession, cognitoSessionInput)
                    expectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testWithValidIdentityAndNoCredentials() {

        let expectation = expectation(description: "startFetchingAWSCredentials")

        let identityIdInput = "identityId"

        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(identityIdResult: .success(identityIdInput))
        let action = ConfigureFetchAWSCredentials(cognitoSession: cognitoSessionInput)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchAWSCredentialEvent else {
                    return
                }

                if case let .fetch(cognitoSession) = event.eventType {
                    XCTAssertEqual(cognitoSession, cognitoSessionInput)
                    expectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

}
