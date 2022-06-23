//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

import AWSCognitoIdentityProvider
import AWSCognitoIdentity

class AWSAuthSignInOperationTests: XCTestCase {

    var queue: OperationQueue?
    let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue?.maxConcurrentOperationCount = 1
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    func testSRPSignInOperationSuccess() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")
        let respondToChallengeExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            return .init(challengeName: .passwordVerifier,
                         challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                         session: "somesession" )
        }

        let respondToChallenge: MockIdentityProvider.MockRespondToAuthChallengeResponse = { _ in
            respondToChallengeExpectation.fulfill()
            return .init(authenticationResult: .init(accessToken: "accesToken",
                                                     expiresIn: 2,
                                                     idToken: "idToken",
                                                     refreshToken: "refreshToken"))
        }

        let getId: MockIdentity.MockGetIdResponse = { _ in
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            let credentials = CognitoIdentityClientTypes.Credentials(accessKeyId: "accessKey",
                                                                     expiration: Date(),
                                                                     secretKey: "secret",
                                                                     sessionToken: "session")
            return .init(credentials: credentials, identityId: "responseIdentityID")
        }
        let request = AuthSignInRequest(username: "username",
                                        password: "password",
                                        options: AuthSignInRequest.Options())

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            identityPoolFactory: {MockIdentity(
                mockGetIdResponse: getId,
                mockGetCredentialsResponse: getCredentials)

            },
            userPoolFactory: { MockIdentityProvider(
                mockInitiateAuthResponse: initiateAuth,
                mockRespondToAuthChallengeResponse: respondToChallenge
            )})
        _ = statemachine.listen {
            print($0)
            switch $0 {
            case .configured(_, let authorizationState):

                if case .waitingToStore(let credentials) = authorizationState {
                    let authEvent = AuthEvent.init(
                        eventType: .receivedCachedCredentials(credentials))
                    statemachine.send(authEvent)
                }
            default: break
            }
        } onSubscribe: {}

        let operation = AWSAuthSignInOperation(
            request,
            authStateMachine: statemachine) {  result in
                switch result {
                case .success(let signUpResult):
                    print("Sign In Result: \(signUpResult)")
                case .failure(let error):
                    XCTAssertNil(error, "Error should not be returned")
                }
                finalCallBackExpectation.fulfill()
            }
        queue?.addOperation(operation)

        wait(for: [initiateAuthExpectation,
                   respondToChallengeExpectation,
                   finalCallBackExpectation], timeout: 2, enforceOrder: true)
    }

    func testSRPSignInWithSMSMFAChallenge() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")
        let respondToChallengeExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            return .init(challengeName: .passwordVerifier,
                         challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                         session: "somesession" )
        }

        let respondToChallenge: MockIdentityProvider.MockRespondToAuthChallengeResponse = { _ in
            respondToChallengeExpectation.fulfill()
            return .init(challengeName: .smsMfa,
                         challengeParameters: InitiateAuthOutputResponse.validSMSChallengeParams,
                         session: "somesession" )
        }

        let request = AuthSignInRequest(username: "username",
                                        password: "password",
                                        options: AuthSignInRequest.Options())

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(
                mockInitiateAuthResponse: initiateAuth,
                mockRespondToAuthChallengeResponse: respondToChallenge
            )})

        let operation = AWSAuthSignInOperation(
            request,
            authStateMachine: statemachine) {  result in
                switch result {
                case .success(let signInResult):
                    switch signInResult.nextStep {
                    case .confirmSignInWithSMSMFACode:
                        finalCallBackExpectation.fulfill()
                    default:
                        XCTFail("Next step should be SMS MFA")
                    }
                case .failure(let error):
                    XCTAssertNil(error, "Error should not be returned")
                }

            }
        queue?.addOperation(operation)

        wait(for: [initiateAuthExpectation,
                   respondToChallengeExpectation,
                   finalCallBackExpectation],
             timeout: 1,
             enforceOrder: true)
    }
}
