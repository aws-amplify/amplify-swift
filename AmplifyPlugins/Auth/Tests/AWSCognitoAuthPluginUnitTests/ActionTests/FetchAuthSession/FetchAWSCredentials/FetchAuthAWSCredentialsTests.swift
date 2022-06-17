//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSCognitoIdentity
import Amplify

@testable import AWSCognitoAuthPlugin

class FetchAuthAWSCredentialsTests: XCTestCase {

    func testNoEnvironment() {

        let expectation = expectation(description: "noAuthorizationEnvironment")

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        action.execute(withDispatcher: MockDispatcher { event in

            guard let event = event as? FetchAuthSessionEvent else {return}

            if case let .throwError(error) = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, .noIdentityPool)
                expectation.fulfill()
            }
        }, environment: MockInvalidEnvironment())
        waitForExpectations(timeout: 0.1)
    }

    func testInvalidIdentitySuccessfullResponse() {

        let expectation = expectation(description: "fetchAWSCredentials")
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                return GetCredentialsForIdentityOutputResponse()
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory)
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        action.execute(withDispatcher: MockDispatcher { event in

            guard let event = event as? FetchAuthSessionEvent else { return }

            if case let .throwError(error) = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, .invalidIdentityID)
                expectation.fulfill()
            }
        }, environment: authEnvironment)

        waitForExpectations(timeout: 0.1)
    }

    func testInvalidAWSCredentialSuccessfulResponse() {

        let expectation = expectation(description: "fetchAWSCredentials")
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                return GetCredentialsForIdentityOutputResponse(identityId: "identityId")
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory)
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchAuthSessionEvent else { return }

                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, .invalidAWSCredentials)
                    expectation.fulfill()
                }
            },
            environment: authEnvironment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testValidSuccessfulResponse() {

        let credentialValidExpectation = expectation(description: "awsCredentialsAreValid")

        let expectedIdentityId = "newIdentityId"
        let expectedSecretKey = "newSecretKey"
        let expectedSessionToken = "newSessionToken"
        let expectedAccessKey = "newAccessKey"

        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                return GetCredentialsForIdentityOutputResponse(
                    credentials: CognitoIdentityClientTypes.Credentials(
                        accessKeyId: expectedAccessKey,
                        expiration: Date(),
                        secretKey: expectedSecretKey,
                        sessionToken: expectedSessionToken),
                    identityId: expectedIdentityId)
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory)
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        action.execute(
            withDispatcher: MockDispatcher { event in

                if let event = event as? FetchAuthSessionEvent,
                   case .fetchedAWSCredentials = event.eventType {
                    credentialValidExpectation.fulfill()
                }
            },
            environment: authEnvironment
        )
        waitForExpectations(timeout: 0.1)
    }

    func testFailureResponse() {
        let expectation = expectation(description: "failureError")
        let testError = NSError(domain: "testError", code: 0, userInfo: nil)

        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                throw testError
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory)
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        action.execute(
            withDispatcher: MockDispatcher { event in

                if let fetchAWSCredentialEvent = event as? FetchAuthSessionEvent,
                   case let .throwError(error) = fetchAWSCredentialEvent.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, .service(testError))
                    expectation.fulfill()
                }
            },
            environment: authEnvironment
        )
        waitForExpectations(timeout: 0.1)
    }

}
