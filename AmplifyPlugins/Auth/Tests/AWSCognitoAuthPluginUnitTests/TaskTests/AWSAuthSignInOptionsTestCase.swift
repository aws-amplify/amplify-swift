//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime

class AWSAuthSignInOptionsTestCase: BasePluginTest {
    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .init(
                    accessToken: Defaults.validAccessToken,
                    expiresIn: 300,
                    idToken: "idToken",
                    newDeviceMetadata: nil,
                    refreshToken: "refreshToken",
                    tokenType: ""),
                challengeName: .none,
                challengeParameters: [:],
                session: "session")
        })
    }

    /// - Given: A sign in task
    /// - When: `metadata` is included in the `AWSAuthSignInOptions`
    /// - Then: That `metadata` should be included in the event's `clientMetadata`
    func test_clientMetadata_noValidationData() async throws {
        let signInOptions = AWSAuthSignInOptions(
            metadata: ["someKey": "metadataValue"]
        )
        let options = AuthSignInRequest.Options(pluginOptions: signInOptions)
        let request = AuthSignInRequest(username: "username", password: "password", options: options)

        let stateMachine = try XCTUnwrap(plugin.authStateMachine)
        let signInTask = AWSAuthSignInTask(
            request,
            authStateMachine: stateMachine,
            configuration: plugin.authConfiguration
        )

        let states = await stateMachine.listen()
        _ = try await signInTask.execute()

        let clientMetadata = await states
            .compactMap(\.authenticationState)
            .compactMap(\.signInEvent)
            .first(where: { _ in true })?
            .clientMetadata

        XCTAssertEqual(clientMetadata, ["someKey": "metadataValue"])
    }

    /// - Given: A sign in task
    /// - When: Deprecated `validationData` is included in the `AWSAuthSignInOptions`
    /// - Then: That `validationData` should be included in the event's `clientMetadata`
    @available(*, deprecated)
    func test_clientMetadata_noMetadata() async throws {
        let signInOptions = AWSAuthSignInOptions(
            validationData: ["someKey": "validationValue"]
        )
        let options = AuthSignInRequest.Options(pluginOptions: signInOptions)
        let request = AuthSignInRequest(username: "username", password: "password", options: options)

        let stateMachine = try XCTUnwrap(plugin.authStateMachine)
        let signInTask = AWSAuthSignInTask(
            request,
            authStateMachine: stateMachine,
            configuration: plugin.authConfiguration
        )

        let states = await stateMachine.listen()
        _ = try await signInTask.execute()

        let clientMetadata = await states
            .compactMap(\.authenticationState)
            .compactMap(\.signInEvent)
            .first(where: { _ in true })?
            .clientMetadata

        XCTAssertEqual(clientMetadata, ["someKey": "validationValue"])
    }

    /// - Given: A sign in task
    /// - When: `metadata` and deprecated `validationData` is included in the `AWSAuthSignInOptions`
    ///  with the same key.
    /// - Then: The value from `metadata` should be included in the event's `clientMetadata`
    @available(*, deprecated)
    func test_clientMetadata_sameKey() async throws {
        let signInOptions = AWSAuthSignInOptions(
            validationData: ["someKey": "validationValue"],
            metadata: ["someKey": "metadataValue"]
        )
        let options = AuthSignInRequest.Options(pluginOptions: signInOptions)
        let request = AuthSignInRequest(username: "username", password: "password", options: options)

        let stateMachine = try XCTUnwrap(plugin.authStateMachine)
        let signInTask = AWSAuthSignInTask(
            request,
            authStateMachine: stateMachine,
            configuration: plugin.authConfiguration
        )

        let states = await stateMachine.listen()
        _ = try await signInTask.execute()

        let clientMetadata = await states
            .compactMap(\.authenticationState)
            .compactMap(\.signInEvent)
            .first(where: { _ in true })?
            .clientMetadata

        XCTAssertEqual(clientMetadata, ["someKey": "metadataValue"])
    }

    /// - Given: A sign in task
    /// - When: `metadata` and deprecated `validationData` is included in the `AWSAuthSignInOptions`
    ///  with the different keys.
    /// - Then: The values from `metadata` and the deprecated `validationData`  should be included in the event's `clientMetadata`
    @available(*, deprecated)
    func test_clientMetadata_differentKeys() async throws {
        let signInOptions = AWSAuthSignInOptions(
            validationData: ["validationKey": "validationValue"],
            metadata: ["metadataKey": "metadataValue"]
        )
        let options = AuthSignInRequest.Options(pluginOptions: signInOptions)
        let request = AuthSignInRequest(username: "username", password: "password", options: options)

        let stateMachine = try XCTUnwrap(plugin.authStateMachine)
        let signInTask = AWSAuthSignInTask(
            request,
            authStateMachine: stateMachine,
            configuration: plugin.authConfiguration
        )

        let states = await stateMachine.listen()
        _ = try await signInTask.execute()

        let clientMetadata = await states
            .compactMap(\.authenticationState)
            .compactMap(\.signInEvent)
            .first(where: { _ in true })?
            .clientMetadata

        XCTAssertEqual(
            clientMetadata,
            [
                "validationKey": "validationValue",
                "metadataKey": "metadataValue"
            ]
        )
    }
}

fileprivate extension AuthState {
    var authenticationState: AuthenticationState? {
        if case .configured(let authenticationState, _) = self {
            return authenticationState
        }
        return nil
    }
}

fileprivate extension AuthenticationState {
    var signInEvent: SignInEventData? {
        if case .signingIn(.signingInWithSRP(_, let eventData)) = self {
            return eventData
        }
        return nil
    }
}
