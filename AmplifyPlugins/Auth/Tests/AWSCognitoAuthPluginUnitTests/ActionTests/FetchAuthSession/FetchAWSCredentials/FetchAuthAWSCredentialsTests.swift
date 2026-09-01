//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import Amplify
import AWSCognitoIdentity

@testable import AWSCognitoAuthPlugin

class FetchAuthAWSCredentialsTests: XCTestCase {

    func testNoEnvironment() async {

        let expectation = expectation(description: "noAuthorizationEnvironment")

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        await action.execute(withDispatcher: MockDispatcher { event in

            guard let event = event as? FetchAuthSessionEvent else {return}

            if case let .throwError(error) = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, .noIdentityPool)
                expectation.fulfill()
            }
        }, environment: MockInvalidEnvironment())

        await fulfillment(
            of: [expectation],
            timeout: 0.1
        )
    }

    func testInvalidIdentitySuccessfullResponse() async {

        let expectation = expectation(description: "fetchAWSCredentials")
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                return GetCredentialsForIdentityOutput()
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory
        )
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        await action.execute(withDispatcher: MockDispatcher { event in

            guard let event = event as? FetchAuthSessionEvent else { return }

            if case let .throwError(error) = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, .invalidIdentityID)
                expectation.fulfill()
            }
        }, environment: authEnvironment)

        await fulfillment(
            of: [expectation],
            timeout: 0.1
        )
    }

    func testInvalidAWSCredentialSuccessfulResponse() async {

        let expectation = expectation(description: "fetchAWSCredentials")
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                return GetCredentialsForIdentityOutput(identityId: "identityId")
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory
        )
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        await action.execute(
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

        await fulfillment(
            of: [expectation],
            timeout: 0.1
        )
    }

    func testValidSuccessfulResponse() async {

        let credentialValidExpectation = expectation(description: "awsCredentialsAreValid")

        let expectedIdentityId = "newIdentityId"
        let expectedSecretKey = "newSecretKey"
        let expectedSessionToken = "newSessionToken"
        let expectedAccessKey = "newAccessKey"

        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                return GetCredentialsForIdentityOutput(
                    credentials: CognitoIdentityClientTypes.Credentials(
                        accessKeyId: expectedAccessKey,
                        expiration: Date(),
                        secretKey: expectedSecretKey,
                        sessionToken: expectedSessionToken
                    ),
                    identityId: expectedIdentityId
                )
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory
        )
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        await action.execute(
            withDispatcher: MockDispatcher { event in

                if let event = event as? FetchAuthSessionEvent,
                   case .fetchedAWSCredentials = event.eventType {
                    credentialValidExpectation.fulfill()
                }
            },
            environment: authEnvironment
        )

        await fulfillment(
            of: [credentialValidExpectation],
            timeout: 0.1
        )
    }

    func testFailureResponse() async {
        let expectation = expectation(description: "failureError")
        let testError = NSError(domain: "testError", code: 0, userInfo: nil)

        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(mockGetCredentialsResponse: { _ in
                throw testError
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory
        )
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "identityID")

        await action.execute(
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

        await fulfillment(
            of: [expectation],
            timeout: 0.1
        )
    }

    /// Authenticated NotAuthorized with a forbidden identity message evicts the
    /// stale identity ID and retries via fresh GetId.
    func testNotAuthorizedEvictsIdentityAndRetries() async {
        await assertStaleIdentityRecovery(
            firstError: AWSCognitoIdentity.NotAuthorizedException(
                message: "Access to Identity 'us-east-1:stale' is forbidden."
            ),
            loginsMap: ["provider.com": "token"]
        )
    }

    /// Same recovery for the `ResourceNotFoundException` variant.
    func testResourceNotFoundEvictsIdentityAndRetries() async {
        await assertStaleIdentityRecovery(
            firstError: AWSCognitoIdentity.ResourceNotFoundException()
        )
    }

    private func assertStaleIdentityRecovery(
        firstError: Error,
        loginsMap: [String: String] = [:]
    ) async {
        let recovered = expectation(description: "recoveredWithFreshIdentity")
        let freshIdentityID = "freshIdentityId"

        let credentialsCallCount = CallCounter()
        let getIdCalled = CallCounter()

        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(
                mockGetIdResponse: { _ in
                    _ = getIdCalled.increment()
                    return GetIdOutput(identityId: freshIdentityID)
                },
                mockGetCredentialsResponse: { input in
                    if credentialsCallCount.increment() == 1 {
                        XCTAssertEqual(input.identityId, "staleIdentityId")
                        throw firstError
                    }
                    XCTAssertEqual(input.identityId, freshIdentityID)
                    return GetCredentialsForIdentityOutput(
                        credentials: CognitoIdentityClientTypes.Credentials(
                            accessKeyId: "accessKey",
                            expiration: Date(),
                            secretKey: "secretKey",
                            sessionToken: "sessionToken"
                        ),
                        identityId: freshIdentityID
                    )
                })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory
        )
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: loginsMap, identityID: "staleIdentityId")

        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? FetchAuthSessionEvent else { return }
                if case let .fetchedAWSCredentials(identityID, _) = event.eventType {
                    XCTAssertEqual(identityID, freshIdentityID)
                    recovered.fulfill()
                }
                if case .throwError = event.eventType {
                    XCTFail("Should recover instead of surfacing an error")
                }
            },
            environment: authEnvironment
        )

        await fulfillment(of: [recovered], timeout: 0.1)
        XCTAssertEqual(getIdCalled.count, 1)
        XCTAssertEqual(credentialsCallCount.count, 2)
    }

    /// Retry is bounded: a second rejection surfaces a terminal error with no extra GetId.
    func testStaleIdentityRetryIsBoundedToSingleAttempt() async {
        let errored = expectation(description: "terminalError")
        let getIdCalled = CallCounter()
        let credentialsCallCount = CallCounter()

        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(
                mockGetIdResponse: { _ in
                    _ = getIdCalled.increment()
                    return GetIdOutput(identityId: "freshIdentityId")
                },
                mockGetCredentialsResponse: { _ in
                    _ = credentialsCallCount.increment()
                    throw AWSCognitoIdentity.ResourceNotFoundException()
                })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory
        )
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: "staleIdentityId")

        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? FetchAuthSessionEvent else { return }
                if case .throwError = event.eventType {
                    errored.fulfill()
                }
            },
            environment: authEnvironment
        )

        await fulfillment(of: [errored], timeout: 0.1)
        XCTAssertEqual(getIdCalled.count, 1)
        XCTAssertEqual(credentialsCallCount.count, 2)
    }

    /// Authenticated NotAuthorized from an invalid/expired login token surfaces
    /// immediately: no GetId retry, single GetCredentials call.
    func testAuthenticatedInvalidTokenNotAuthorizedSurfacesImmediately() async {
        let errored = expectation(description: "terminalError")
        let getIdCalled = CallCounter()
        let credentialsCallCount = CallCounter()

        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(
                mockGetIdResponse: { _ in
                    _ = getIdCalled.increment()
                    return GetIdOutput(identityId: "freshIdentityId")
                },
                mockGetCredentialsResponse: { _ in
                    _ = credentialsCallCount.increment()
                    throw AWSCognitoIdentity.NotAuthorizedException(
                        message: "Invalid login token. Token expired."
                    )
                })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: IdentityPoolConfigurationData.testData,
            cognitoIdentityFactory: identityProviderFactory
        )
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            authZEnvironment: authorizationEnvironment)

        let action = FetchAuthAWSCredentials(
            loginsMap: ["provider.com": "token"], identityID: "identityID")

        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? FetchAuthSessionEvent else { return }
                if case .throwError = event.eventType {
                    errored.fulfill()
                }
            },
            environment: authEnvironment
        )

        await fulfillment(of: [errored], timeout: 0.1)
        XCTAssertEqual(getIdCalled.count, 0)
        XCTAssertEqual(credentialsCallCount.count, 1)
    }
}

private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    @discardableResult
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
