//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import XCTest
@testable import AWSCognitoAuthPlugin

class InputUsernameDeviceKeyTests: XCTestCase {

    // MARK: - SignedInData Codable backwards compatibility

    /// Test that SignedInData without inputUsername can be decoded (upgrade path)
    ///
    /// - Given: JSON data from a previous SDK version without the inputUsername field
    /// - When: Decoding into SignedInData
    /// - Then: inputUsername should be nil and all other fields decode correctly
    func testSignedInDataDecodesWithoutInputUsername() throws {
        let tokens = AWSCognitoUserPoolTokens.testData
        let original = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: tokens
        )

        let encoded = try JSONEncoder().encode(original)
        var jsonObject = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        jsonObject.removeValue(forKey: "inputUsername")
        let modifiedData = try JSONSerialization.data(withJSONObject: jsonObject)

        let decoded = try JSONDecoder().decode(SignedInData.self, from: modifiedData)
        XCTAssertNil(decoded.inputUsername)
        XCTAssertEqual(decoded.userId, original.userId)
        XCTAssertEqual(decoded.username, original.username)
    }

    /// Test that SignedInData with inputUsername round-trips through encode/decode
    ///
    /// - Given: SignedInData with inputUsername set
    /// - When: Encoding then decoding
    /// - Then: inputUsername should survive the round trip
    func testSignedInDataRoundTripsWithInputUsername() throws {
        let tokens = AWSCognitoUserPoolTokens.testData
        let original = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: tokens,
            inputUsername: "user@example.com"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SignedInData.self, from: encoded)

        XCTAssertEqual(decoded.inputUsername, "user@example.com")
    }

    /// Test that AmplifyCredentials containing SignedInData with inputUsername decodes correctly
    ///
    /// - Given: AmplifyCredentials with SignedInData that has inputUsername
    /// - When: Encoding then decoding
    /// - Then: inputUsername should be preserved through the AmplifyCredentials wrapper
    func testAmplifyCredentialsRoundTripsWithInputUsername() throws {
        let tokens = AWSCognitoUserPoolTokens.testData
        let signedInData = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: tokens,
            inputUsername: "user@example.com"
        )

        let credentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
        let encoded = try JSONEncoder().encode(credentials)
        let decoded = try JSONDecoder().decode(AmplifyCredentials.self, from: encoded)

        if case .userPoolOnly(let decodedData) = decoded {
            XCTAssertEqual(decodedData.inputUsername, "user@example.com")
        } else {
            XCTFail("Expected userPoolOnly credentials")
        }
    }

    /// Test that AmplifyCredentials from older SDK version (without inputUsername) decodes
    ///
    /// - Given: Encoded AmplifyCredentials from before inputUsername was added
    /// - When: Decoding
    /// - Then: Should decode successfully with inputUsername as nil
    func testAmplifyCredentialsBackwardsCompatibility() throws {
        let tokens = AWSCognitoUserPoolTokens.testData
        let signedInData = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: tokens
        )

        let credentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
        let encoded = try JSONEncoder().encode(credentials)

        // Simulate old data by stripping inputUsername from the JSON
        var jsonString = String(data: encoded, encoding: .utf8)!
        jsonString = jsonString.replacingOccurrences(
            of: ",\"inputUsername\":{\"some\":\"[^\"]*\"}",
            with: "",
            options: .regularExpression
        )
        // Also remove if it's encoded as null
        jsonString = jsonString.replacingOccurrences(
            of: ",\"inputUsername\":null",
            with: ""
        )
        jsonString = jsonString.replacingOccurrences(
            of: "\"inputUsername\":null,",
            with: ""
        )

        let modifiedData = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AmplifyCredentials.self, from: modifiedData)

        if case .userPoolOnly(let decodedData) = decoded {
            XCTAssertNil(decodedData.inputUsername)
        } else {
            XCTFail("Expected userPoolOnly credentials")
        }
    }

    // MARK: - RespondToAuthChallenge inputUsername propagation

    /// Test that RespondToAuthChallenge preserves inputUsername through encode/decode
    ///
    /// - Given: RespondToAuthChallenge with inputUsername set
    /// - When: Encoding then decoding
    /// - Then: inputUsername should survive the round trip
    func testRespondToAuthChallengeRoundTripsInputUsername() throws {
        let challenge = RespondToAuthChallenge(
            challenge: .smsMfa,
            availableChallenges: [],
            username: "cognito-canonical-id",
            session: "session",
            parameters: [:],
            inputUsername: "user@example.com"
        )

        let encoded = try JSONEncoder().encode(challenge)
        let decoded = try JSONDecoder().decode(RespondToAuthChallenge.self, from: encoded)

        XCTAssertEqual(decoded.inputUsername, "user@example.com")
        XCTAssertEqual(decoded.username, "cognito-canonical-id")
    }

    /// Test that RespondToAuthChallenge without inputUsername decodes with nil
    ///
    /// - Given: RespondToAuthChallenge JSON without inputUsername field
    /// - When: Decoding
    /// - Then: inputUsername should be nil
    func testRespondToAuthChallengeBackwardsCompatibility() throws {
        let challenge = RespondToAuthChallenge(
            challenge: .smsMfa,
            availableChallenges: [],
            username: "user",
            session: "session",
            parameters: [:]
        )

        let encoded = try JSONEncoder().encode(challenge)
        var jsonObject = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        jsonObject.removeValue(forKey: "inputUsername")
        let modifiedData = try JSONSerialization.data(withJSONObject: jsonObject)

        let decoded = try JSONDecoder().decode(RespondToAuthChallenge.self, from: modifiedData)
        XCTAssertNil(decoded.inputUsername)
    }

    // MARK: - parseResponse inputUsername threading

    /// Test that parseResponse sets inputUsername on SignedInData for confirmDevice
    ///
    /// - Given: A successful auth response with new device metadata
    /// - When: parseResponse is called with a username
    /// - Then: The confirmDevice event should contain SignedInData with inputUsername set
    func testParseResponseSetsInputUsernameOnConfirmDevice() {
        let result = CognitoIdentityProviderClientTypes.AuthenticationResultType(
            accessToken: Defaults.validAccessToken,
            expiresIn: 3_600,
            idToken: "idTokenXXX",
            newDeviceMetadata: .init(deviceGroupKey: "groupKey", deviceKey: "deviceKey"),
            refreshToken: "refreshTokenXXX",
            tokenType: "Bearer"
        )

        let response = InitiateAuthOutput(
            authenticationResult: result,
            challengeName: nil,
            challengeParameters: nil,
            session: nil
        )

        let event = UserPoolSignInHelper.parseResponse(
            response,
            for: "cognito-canonical-id",
            signInMethod: .apiBased(.userSRP),
            inputUsername: "user@example.com"
        )

        guard let signInEvent = event as? SignInEvent,
              case .confirmDevice(let signedInData) = signInEvent.eventType else {
            XCTFail("Expected confirmDevice event")
            return
        }

        XCTAssertEqual(signedInData.inputUsername, "user@example.com")
    }

    /// Test that parseResponse falls back to 'for' username when inputUsername is nil
    ///
    /// - Given: A successful auth response with new device metadata
    /// - When: parseResponse is called without explicit inputUsername
    /// - Then: SignedInData.inputUsername should be set to the 'for' username parameter
    func testParseResponseFallsBackToUsernameWhenNoInputUsername() {
        let result = CognitoIdentityProviderClientTypes.AuthenticationResultType(
            accessToken: Defaults.validAccessToken,
            expiresIn: 3_600,
            idToken: "idTokenXXX",
            newDeviceMetadata: .init(deviceGroupKey: "groupKey", deviceKey: "deviceKey"),
            refreshToken: "refreshTokenXXX",
            tokenType: "Bearer"
        )

        let response = InitiateAuthOutput(
            authenticationResult: result,
            challengeName: nil,
            challengeParameters: nil,
            session: nil
        )

        let event = UserPoolSignInHelper.parseResponse(
            response,
            for: "user@example.com",
            signInMethod: .apiBased(.userPassword)
        )

        guard let signInEvent = event as? SignInEvent,
              case .confirmDevice(let signedInData) = signInEvent.eventType else {
            XCTFail("Expected confirmDevice event")
            return
        }

        XCTAssertEqual(signedInData.inputUsername, "user@example.com")
    }

    /// Test that parseResponse sets inputUsername on RespondToAuthChallenge for challenge responses
    ///
    /// - Given: An auth response with an MFA challenge
    /// - When: parseResponse is called with an explicit inputUsername
    /// - Then: The challenge event should carry inputUsername
    func testParseResponseSetsInputUsernameOnChallenge() {
        let response = InitiateAuthOutput(
            authenticationResult: nil,
            challengeName: .smsMfa,
            challengeParameters: [:],
            session: "session"
        )

        let event = UserPoolSignInHelper.parseResponse(
            response,
            for: "cognito-canonical-id",
            signInMethod: .apiBased(.userSRP),
            inputUsername: "user@example.com"
        )

        guard let signInEvent = event as? SignInEvent,
              case .receivedChallenge(let challenge) = signInEvent.eventType else {
            XCTFail("Expected receivedChallenge event")
            return
        }

        XCTAssertEqual(challenge.inputUsername, "user@example.com")
        XCTAssertEqual(challenge.username, "cognito-canonical-id")
    }

    /// Test that parseResponse sets inputUsername on finalizeSignIn (no new device)
    ///
    /// - Given: A successful auth response without new device metadata
    /// - When: parseResponse is called with an explicit inputUsername
    /// - Then: The finalizeSignIn event should have inputUsername on SignedInData
    func testParseResponseSetsInputUsernameOnFinalizeSignIn() {
        let result = CognitoIdentityProviderClientTypes.AuthenticationResultType(
            accessToken: Defaults.validAccessToken,
            expiresIn: 3_600,
            idToken: "idTokenXXX",
            newDeviceMetadata: nil,
            refreshToken: "refreshTokenXXX",
            tokenType: "Bearer"
        )

        let response = InitiateAuthOutput(
            authenticationResult: result,
            challengeName: nil,
            challengeParameters: nil,
            session: nil
        )

        let event = UserPoolSignInHelper.parseResponse(
            response,
            for: "cognito-id",
            signInMethod: .apiBased(.userSRP),
            inputUsername: "user@example.com"
        )

        guard let signInEvent = event as? SignInEvent,
              case .finalizeSignIn(let signedInData) = signInEvent.eventType else {
            XCTFail("Expected finalizeSignIn event")
            return
        }

        XCTAssertEqual(signedInData.inputUsername, "user@example.com")
    }

    // MARK: - VerifyPasswordSRP inputUsername threading

    /// Test that VerifyPasswordSRP passes original inputUsername through confirmDevice
    ///
    /// - Given: VerifyPasswordSRP action where Cognito challenge overwrites USERNAME
    /// - When: The auth response includes new device metadata triggering confirmDevice
    /// - Then: The confirmDevice event should carry the original user input, not the Cognito canonical
    func testVerifyPasswordSRPPassesInputUsernameOnConfirmDevice() async {
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutput.testDataWithNewDevice()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutput.validTestData
        let action = VerifyPasswordSRP(
            stateData: SRPStateData.testData,
            authResponse: data,
            clientMetadata: [:]
        )

        let confirmDeviceReceived = expectation(description: "confirmDeviceReceived")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            if case .confirmDevice(let signedInData) = event.eventType {
                XCTAssertNotNil(signedInData.inputUsername)
                confirmDeviceReceived.fulfill()
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await fulfillment(of: [confirmDeviceReceived], timeout: 0.1)
    }

    // MARK: - VerifySignInChallenge inputUsername forwarding

    /// Test that VerifySignInChallenge forwards inputUsername from challenge through confirmDevice
    ///
    /// - Given: VerifySignInChallenge with a challenge that carries inputUsername
    /// - When: Auth response includes new device metadata
    /// - Then: confirmDevice event should carry the inputUsername from the original challenge
    func testVerifySignInChallengeForwardsInputUsernameOnConfirmDevice() async {
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutput.testDataWithNewDevice()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let challengeWithInputUsername = RespondToAuthChallenge(
            challenge: .smsMfa,
            availableChallenges: [],
            username: "cognito-canonical-id",
            session: "mockSession",
            parameters: [:],
            inputUsername: "user@example.com"
        )

        let confirmEvent = ConfirmSignInEventData(
            answer: "123456",
            attributes: [:],
            metadata: [:],
            friendlyDeviceName: nil,
            presentationAnchor: nil
        )

        let action = VerifySignInChallenge(
            challenge: challengeWithInputUsername,
            confirmSignEventData: confirmEvent,
            signInMethod: .apiBased(.userSRP),
            currentSignInStep: .confirmSignInWithSMSMFACode(.init(
                destination: .sms(nil),
                attributeKey: nil
            ), nil)
        )

        let confirmDeviceReceived = expectation(description: "confirmDeviceReceived")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignInEvent else { return }

            if case .confirmDevice(let signedInData) = event.eventType {
                XCTAssertEqual(signedInData.inputUsername, "user@example.com")
                confirmDeviceReceived.fulfill()
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await fulfillment(of: [confirmDeviceReceived], timeout: 0.1)
    }
}
