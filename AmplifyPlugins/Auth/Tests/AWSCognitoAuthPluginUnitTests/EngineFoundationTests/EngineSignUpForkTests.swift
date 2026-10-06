//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Tests for the engine's sign-up forks: `EngineSignUpResult`, `EngineSignUpStep` and
/// `EngineUserAttribute`, against the public types they mirror, and for the plugin's converters in
/// `Support/EngineBridge/AuthSignUpResult+Engine.swift`. The sign-in and delivery-detail forks are in
/// `EnginePayloadForkTests`.
class EngineSignUpForkTests: XCTestCase {

    private static let infos = EnginePayloadForkTests.infos

    // MARK: EngineSignUpResult

    private static var signUpSteps: [AuthSignUpStep] {
        var steps: [AuthSignUpStep] = [.confirmUser(), .completeAutoSignIn("session"), .completeAutoSignIn(""), .done]
        for details in [nil, AuthCodeDeliveryDetails(destination: .email("a@example.com"), attributeKey: .email)] {
            for info in infos {
                for userId in [nil, "sub"] {
                    steps.append(.confirmUser(details, info, userId))
                }
            }
        }
        return steps
    }

    private func assertSame(
        _ step: AuthSignUpStep,
        _ engine: EngineSignUpStep,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch (step, engine) {
        case (.confirmUser(let details, let info, let userId), .confirmUser(let engineDetails, let engineInfo, let engineUserId)):
            XCTAssertEqual(details, engineDetails.map { AuthCodeDeliveryDetails($0) }, file: file, line: line)
            XCTAssertEqual(details?.attributeKey?.rawValue, engineDetails?.attributeKey, file: file, line: line)
            XCTAssertEqual(info, engineInfo, file: file, line: line)
            XCTAssertEqual(userId, engineUserId, file: file, line: line)
        case (.completeAutoSignIn(let session), .completeAutoSignIn(let engineSession)):
            XCTAssertEqual(session, engineSession, file: file, line: line)
        case (.done, .done):
            break
        default:
            XCTFail("\(step) became \(engine)", file: file, line: line)
        }
    }

    /// Test that sign-up results convert case to case, in both directions
    ///
    /// - Given: Every `AuthSignUpStep` case, with each combination of payloads, with and without a user ID
    /// - When:
    ///    - Each result is converted to the fork, and back
    /// - Then:
    ///    - The step, its payloads, `userID` and `isSignUpComplete` survive both directions
    ///
    func testSignUpResultRoundTrip() {
        for step in Self.signUpSteps {
            for userID in [nil, "user-id"] {
                let result = AuthSignUpResult(step, userID: userID)
                let engine = EngineSignUpResult(result)
                assertSame(result.nextStep, engine.nextStep)
                XCTAssertEqual(engine.userID, result.userID)
                XCTAssertEqual(engine.isSignUpComplete, result.isSignUpComplete)

                let back = AuthSignUpResult(engine)
                assertSame(back.nextStep, engine.nextStep)
                assertSame(back.nextStep, EngineSignUpResult(back).nextStep)
                XCTAssertEqual(back.userID, result.userID)
                XCTAssertEqual(back.isSignUpComplete, result.isSignUpComplete)
            }
        }
    }

    /// Test that the fork's defaults are the public type's
    ///
    /// - Given: A result and a `confirmUser` step built with every default
    /// - When:
    ///    - They are compared with the public type built the same way
    /// - Then:
    ///    - `userID` and each `confirmUser` payload default to `nil`
    ///
    func testSignUpDefaults() {
        let engine = EngineSignUpResult(.confirmUser())
        assertSame(AuthSignUpResult(.confirmUser()).nextStep, engine.nextStep)
        XCTAssertNil(engine.userID)
        XCTAssertFalse(engine.isSignUpComplete)
    }

    // MARK: EngineUserAttribute

    /// Test that user attributes carry the key's Cognito name
    ///
    /// - Given: Attributes with standard, custom and unknown keys
    /// - When:
    ///    - Each is converted to `EngineUserAttribute`, and back
    /// - Then:
    ///    - The engine key is `key.rawValue` (what `InitiateSignUp` sent before the fork), the value is kept, and
    ///      the round trip gives the same key
    ///
    func testUserAttributeRoundTrip() {
        let keys: [AuthUserAttributeKey] = [
            .address, .birthDate, .email, .emailVerified, .familyName, .gender, .givenName, .locale,
            .middleName, .name, .nickname, .phoneNumber, .phoneNumberVerified, .picture, .preferredUsername,
            .profile, .sub, .updatedAt, .website, .zoneInfo, .custom("favorite"), .unknown("not_a_key")
        ]
        for key in keys {
            let attribute = AuthUserAttribute(key, value: "value-\(key.rawValue)")
            let engine = EngineUserAttribute(attribute)
            XCTAssertEqual(engine.key, key.rawValue)
            XCTAssertEqual(engine.value, attribute.value)
            let back = AuthUserAttribute(engine)
            XCTAssertEqual(back.key, key)
            XCTAssertEqual(back.value, attribute.value)
        }
    }

    // MARK: The split SDK helpers (`SignUpOutputResponse+Helper` / `CodeDeliveryDetailsType+Amplify`)

    private static let deliveryTypes: [CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType] = {
        let media: [CognitoIdentityProviderClientTypes.DeliveryMediumType?] = [.email, .sms, .sdkUnknown("PUSH"), nil]
        let names: [String?] = [nil, "email", "phone_number", "custom:favorite", "not_a_key"]
        return media.flatMap { medium in
            names.map { name in
                .init(attributeName: name, deliveryMedium: medium, destination: "d***@example.com")
            }
        }
    }()

    /// Test that the plugin half builds the delivery details the pre-split helper built
    ///
    /// - Given: SDK delivery details for every medium, with and without each kind of attribute name
    /// - When:
    ///    - `toAuthCodeDeliveryDetails()` and `toDeliveryDestination()` convert them
    /// - Then:
    ///    - Email and SMS map to their cases and anything else to `.unknown`, with the destination kept,
    ///      and the key is `AuthUserAttributeKey(rawValue:)` of the name, or `nil` without one
    ///
    func testPluginHalfBuildsThePreSplitDeliveryDetails() {
        for sdk in Self.deliveryTypes {
            let destination: DeliveryDestination
            switch sdk.deliveryMedium {
            case .email: destination = .email(sdk.destination)
            case .sms: destination = .sms(sdk.destination)
            default: destination = .unknown(sdk.destination)
            }
            let expected = AuthCodeDeliveryDetails(
                destination: destination,
                attributeKey: sdk.attributeName.map { AuthUserAttributeKey(rawValue: $0) }
            )
            XCTAssertEqual(sdk.toDeliveryDestination(), destination)
            XCTAssertEqual(sdk.toAuthCodeDeliveryDetails(), expected)
            XCTAssertEqual(sdk.toEngineCodeDeliveryDetails().attributeKey, sdk.attributeName)
        }
    }

    /// Test that the engine half's sign-up result is the pre-split one
    ///
    /// - Given: Confirmed and unconfirmed `SignUpOutput`s, with and without delivery details
    /// - When:
    ///    - `authResponse` builds the engine result and the plugin converts it
    /// - Then:
    ///    - A confirmed user gives `.done`; an unconfirmed one `.confirmUser(details, nil, sub)`; the user ID
    ///      is the sub in both
    ///
    func testEngineHalfBuildsThePreSplitSignUpResult() {
        for details in [nil] + Self.deliveryTypes.prefix(3).map({ Optional($0) }) {
            for confirmed in [true, false] {
                let output = SignUpOutput(codeDeliveryDetails: details, userConfirmed: confirmed, userSub: "sub")
                let result = AuthSignUpResult(output.authResponse)
                XCTAssertEqual(result.userID, "sub")
                switch result.nextStep {
                case .done:
                    XCTAssertTrue(confirmed)
                case .confirmUser(let delivery, let info, let userId):
                    XCTAssertFalse(confirmed)
                    XCTAssertEqual(delivery, details?.toAuthCodeDeliveryDetails())
                    XCTAssertNil(info)
                    XCTAssertEqual(userId, "sub")
                case .completeAutoSignIn:
                    XCTFail("unexpected auto sign-in step")
                }
            }
        }
    }
}
