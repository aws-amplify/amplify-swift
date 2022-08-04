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

    func skip_testSRPSignInOperationSuccess() async throws {
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

        let task = AWSAuthSignInTask(request, authStateMachine: statemachine)
        do {
            let result = try await task.execute()
            print("Sign In Result: \(result)")
            finalCallBackExpectation.fulfill()
        } catch {
            XCTAssertNil(error, "Error should not be returned")
        }

        wait(for: [initiateAuthExpectation,
                   respondToChallengeExpectation,
                   finalCallBackExpectation], timeout: 2, enforceOrder: true)
    }

    func skip_testSRPSignInWithSMSMFAChallenge() async throws {
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

        let task = AWSAuthSignInTask(request, authStateMachine: statemachine)
        do {
            let result = try await task.execute()
            print("Sign In Result: \(result)")
            guard case AuthSignInStep.confirmSignInWithSMSMFACode(_, _) = result.nextStep else {
                XCTFail("Incorrect next sign in step")
                return
            }
            finalCallBackExpectation.fulfill()
        } catch {
            XCTAssertNil(error, "Error should not be returned")
        }

        wait(for: [initiateAuthExpectation,
                   respondToChallengeExpectation,
                   finalCallBackExpectation],
             timeout: 1,
             enforceOrder: true)
    }
}
