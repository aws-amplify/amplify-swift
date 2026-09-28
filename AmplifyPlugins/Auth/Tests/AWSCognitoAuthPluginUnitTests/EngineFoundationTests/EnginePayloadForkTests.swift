//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Tests for the engine's payload forks: `EngineSignInStep` and its payload mirrors,
/// `EngineMFAType`, `EngineCodeDeliveryDetails`, `EngineSignUpResult` and `EngineUserAttribute`, against the
/// public types they mirror, and for the plugin's converters in `Support/EngineBridge/`.
class EnginePayloadForkTests: XCTestCase {

    // MARK: Values

    static let mfaTypes: [MFAType] = [.sms, .totp, .email]

    static var factors: [AuthFactorType] {
        var factors: [AuthFactorType] = [.password, .passwordSRP, .smsOTP, .emailOTP]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            factors.append(.webAuthn)
        }
        #endif
        return factors
    }

    static let destinations: [DeliveryDestination] = [
        .email("a@example.com"), .email(nil),
        .phone("+15555550100"), .phone(nil),
        .sms("+15555550100"), .sms(nil),
        .unknown("somewhere"), .unknown(nil)
    ]

    /// Wire names as Cognito sends them: standard, custom, unknown and empty.
    static let attributeNames: [String?] = [nil, "email", "phone_number", "custom:favorite", "custom:", "not_a_key", ""]

    static var deliveryDetails: [AuthCodeDeliveryDetails] {
        destinations.flatMap { destination in
            attributeNames.map { name in
                AuthCodeDeliveryDetails(
                    destination: destination,
                    attributeKey: name.map { AuthUserAttributeKey(rawValue: $0) }
                )
            }
        }
    }

    static let infos: [AdditionalInfo?] = [nil, [:], ["key": "value", "other": ""]]

    static var mfaSets: [Set<MFAType>] {
        [[], [.sms], [.totp], [.email], [.totp, .email], Set(mfaTypes)]
    }

    static var factorSets: [Set<AuthFactorType>] {
        [[], [.password], [.passwordSRP, .emailOTP], Set(factors)]
    }

    /// At least one value of every `AuthSignInStep` case, most of them with several payloads.
    static var signInSteps: [AuthSignInStep] {
        let details = [
            AuthCodeDeliveryDetails(destination: .sms("+15555550100")),
            AuthCodeDeliveryDetails(destination: .email("a@example.com"), attributeKey: .email),
            AuthCodeDeliveryDetails(destination: .unknown(nil), attributeKey: .custom("x"))
        ]
        var steps: [AuthSignInStep] = []
        for detail in details {
            for info in infos {
                steps.append(.confirmSignInWithSMSMFACode(detail, info))
            }
            steps.append(.confirmSignInWithOTP(detail))
        }
        for info in infos {
            steps.append(.confirmSignInWithCustomChallenge(info))
            steps.append(.confirmSignInWithNewPassword(info))
            steps.append(.resetPassword(info))
            steps.append(.confirmSignUp(info))
        }
        steps += [.confirmSignInWithPassword, .confirmSignInWithTOTPCode, .continueSignInWithEmailMFASetup, .done]
        steps += [
            .continueSignInWithTOTPSetup(.init(sharedSecret: "secret", username: "user")),
            .continueSignInWithTOTPSetup(.init(sharedSecret: "", username: "other"))
        ]
        for set in mfaSets {
            steps.append(.continueSignInWithMFASelection(set))
            steps.append(.continueSignInWithMFASetupSelection(set))
        }
        for set in factorSets {
            steps.append(.continueSignInWithFirstFactorSelection(set))
        }
        return steps
    }

    // MARK: Case names (exhaustive switches, so a new case on either side fails to compile)

    // swiftlint:disable cyclomatic_complexity

    private func caseName(_ step: AuthSignInStep) -> String {
        switch step {
        case .confirmSignInWithSMSMFACode: return "confirmSignInWithSMSMFACode"
        case .confirmSignInWithCustomChallenge: return "confirmSignInWithCustomChallenge"
        case .confirmSignInWithNewPassword: return "confirmSignInWithNewPassword"
        case .confirmSignInWithPassword: return "confirmSignInWithPassword"
        case .confirmSignInWithTOTPCode: return "confirmSignInWithTOTPCode"
        case .continueSignInWithTOTPSetup: return "continueSignInWithTOTPSetup"
        case .continueSignInWithMFASelection: return "continueSignInWithMFASelection"
        case .continueSignInWithEmailMFASetup: return "continueSignInWithEmailMFASetup"
        case .continueSignInWithMFASetupSelection: return "continueSignInWithMFASetupSelection"
        case .confirmSignInWithOTP: return "confirmSignInWithOTP"
        case .continueSignInWithFirstFactorSelection: return "continueSignInWithFirstFactorSelection"
        case .resetPassword: return "resetPassword"
        case .confirmSignUp: return "confirmSignUp"
        case .done: return "done"
        }
    }

    private func caseName(_ step: EngineSignInStep) -> String {
        switch step {
        case .confirmSignInWithSMSMFACode: return "confirmSignInWithSMSMFACode"
        case .confirmSignInWithCustomChallenge: return "confirmSignInWithCustomChallenge"
        case .confirmSignInWithNewPassword: return "confirmSignInWithNewPassword"
        case .confirmSignInWithPassword: return "confirmSignInWithPassword"
        case .confirmSignInWithTOTPCode: return "confirmSignInWithTOTPCode"
        case .continueSignInWithTOTPSetup: return "continueSignInWithTOTPSetup"
        case .continueSignInWithMFASelection: return "continueSignInWithMFASelection"
        case .continueSignInWithEmailMFASetup: return "continueSignInWithEmailMFASetup"
        case .continueSignInWithMFASetupSelection: return "continueSignInWithMFASetupSelection"
        case .confirmSignInWithOTP: return "confirmSignInWithOTP"
        case .continueSignInWithFirstFactorSelection: return "continueSignInWithFirstFactorSelection"
        case .resetPassword: return "resetPassword"
        case .confirmSignUp: return "confirmSignUp"
        case .done: return "done"
        }
    }

    // swiftlint:enable cyclomatic_complexity

    // MARK: EngineSignInStep ↔ AuthSignInStep

    /// Test that the step table is exhaustive and that each case maps onto the same case
    ///
    /// - Given: One or more values of every `AuthSignInStep` case
    /// - When:
    ///    - Each is converted to `EngineSignInStep`, and back
    /// - Then:
    ///    - All 14 case names are covered; each value keeps its case name in both directions, and the round
    ///      trip gives an equal value
    ///
    func testSignInStepTableIsExhaustiveAndCaseForCase() {
        let steps = Self.signInSteps
        XCTAssertEqual(Set(steps.map(caseName)).count, 14)
        for step in steps {
            let engine = EngineSignInStep(step)
            XCTAssertEqual(caseName(engine), caseName(step))
            XCTAssertEqual(AuthSignInStep(engine), step, "\(step)")
            XCTAssertEqual(EngineSignInStep(AuthSignInStep(engine)), engine, "\(step)")
        }
    }

    /// Test that each payload survives the conversion field by field
    ///
    /// - Given: One or more values of every `AuthSignInStep` case with a payload
    /// - When:
    ///    - Each is converted to `EngineSignInStep`
    /// - Then:
    ///    - Delivery details, additional info, TOTP details, MFA types and factors are the converted
    ///      payloads of the public value
    ///
    func testSignInStepPayloadsConvertFieldByField() throws {
        for step in Self.signInSteps {
            switch (step, EngineSignInStep(step)) {
            case (.confirmSignInWithSMSMFACode(let details, let info), .confirmSignInWithSMSMFACode(let engine, let engineInfo)):
                assertSame(details, engine)
                XCTAssertEqual(info, engineInfo)
            case (.confirmSignInWithOTP(let details), .confirmSignInWithOTP(let engine)):
                assertSame(details, engine)
            case (.confirmSignInWithCustomChallenge(let info), .confirmSignInWithCustomChallenge(let engineInfo)),
                 (.confirmSignInWithNewPassword(let info), .confirmSignInWithNewPassword(let engineInfo)),
                 (.resetPassword(let info), .resetPassword(let engineInfo)),
                 (.confirmSignUp(let info), .confirmSignUp(let engineInfo)):
                XCTAssertEqual(info, engineInfo)
            case (.continueSignInWithTOTPSetup(let details), .continueSignInWithTOTPSetup(let engine)):
                XCTAssertEqual(details.sharedSecret, engine.sharedSecret)
                XCTAssertEqual(details.username, engine.username)
            case (.continueSignInWithMFASelection(let types), .continueSignInWithMFASelection(let engine)),
                 (.continueSignInWithMFASetupSelection(let types), .continueSignInWithMFASetupSelection(let engine)):
                XCTAssertEqual(Set(types.map(\.challengeResponse)), Set(engine.map(\.challengeResponse)))
                XCTAssertEqual(types.count, engine.count)
            case (.continueSignInWithFirstFactorSelection(let factors), .continueSignInWithFirstFactorSelection(let engine)):
                XCTAssertEqual(Set(factors.map(\.challengeResponse)), Set(engine.map(\.challengeResponse)))
                XCTAssertEqual(factors.count, engine.count)
            case (.confirmSignInWithPassword, .confirmSignInWithPassword),
                 (.confirmSignInWithTOTPCode, .confirmSignInWithTOTPCode),
                 (.continueSignInWithEmailMFASetup, .continueSignInWithEmailMFASetup),
                 (.done, .done):
                break
            default:
                XCTFail("\(step) changed case")
            }
        }
    }

    /// Test that `EngineSignInStep ==` agrees with `AuthSignInStep ==` on every pair
    ///
    /// - Given: The step values, including values of one case that differ only in their payload
    /// - When:
    ///    - Every ordered pair is compared on both sides
    /// - Then:
    ///    - The two results are the same for every pair
    ///
    func testSignInStepEqualityTable() {
        let steps = Self.signInSteps
        let engineSteps = steps.map { EngineSignInStep($0) }
        var equalPairs = 0
        for (lhsIndex, lhs) in steps.enumerated() {
            for (rhsIndex, rhs) in steps.enumerated() {
                let engineEqual = engineSteps[lhsIndex] == engineSteps[rhsIndex]
                XCTAssertEqual(engineEqual, conformanceEqual(lhs, rhs), "\(lhs) vs \(rhs)")
                if engineEqual { equalPairs += 1 }
            }
        }
        XCTAssertEqual(equalPairs, steps.count, "only a value equals itself: the table has no duplicates")
    }

    /// `==` through the `Equatable` conformance, which is Amplify's synthesized one. A direct `==` on
    /// `AuthSignInStep` here would pick the test harness's case-only operator
    /// (`TestHarness/AuthCodableImplementations/Results/AuthSignInResult+Codable.swift`).
    private func conformanceEqual<T: Equatable>(_ lhs: T, _ rhs: T) -> Bool {
        lhs == rhs
    }

    // MARK: EngineCodeDeliveryDetails

    private func assertSame(
        _ details: AuthCodeDeliveryDetails,
        _ engine: EngineCodeDeliveryDetails,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(details.attributeKey?.rawValue, engine.attributeKey, file: file, line: line)
        switch (details.destination, engine.destination) {
        case (.email(let lhs), .email(let rhs)),
             (.phone(let lhs), .phone(let rhs)),
             (.sms(let lhs), .sms(let rhs)),
             (.unknown(let lhs), .unknown(let rhs)):
            XCTAssertEqual(lhs, rhs, file: file, line: line)
        default:
            XCTFail("\(details.destination) became \(engine.destination)", file: file, line: line)
        }
    }

    /// Test that delivery details convert case to case and field by field, in both directions
    ///
    /// - Given: Every destination case, with and without a value, times a corpus of attribute wire names
    /// - When:
    ///    - Each public value is converted to the fork and back, and each fork value to the public type
    ///      and back
    /// - Then:
    ///    - Destinations keep their case and value, the attribute name is the key's `rawValue`, and both
    ///      round trips give equal values
    ///
    func testCodeDeliveryDetailsRoundTrip() {
        for details in Self.deliveryDetails {
            let engine = EngineCodeDeliveryDetails(details)
            assertSame(details, engine)
            XCTAssertEqual(AuthCodeDeliveryDetails(engine), details)
            XCTAssertEqual(EngineCodeDeliveryDetails(AuthCodeDeliveryDetails(engine)), engine)
        }
        for destination in Self.destinations {
            for name in Self.attributeNames {
                let engine = EngineCodeDeliveryDetails(
                    destination: EngineDeliveryDestination(destination),
                    attributeKey: name
                )
                XCTAssertEqual(EngineCodeDeliveryDetails(AuthCodeDeliveryDetails(engine)), engine)
                XCTAssertEqual(
                    AuthCodeDeliveryDetails(engine).attributeKey,
                    name.map { AuthUserAttributeKey(rawValue: $0) }
                )
            }
        }
    }

    /// Test that `EngineCodeDeliveryDetails ==` agrees with `AuthCodeDeliveryDetails ==`
    ///
    /// - Given: The delivery-detail values built from wire names
    /// - When:
    ///    - Every ordered pair is compared on both sides
    /// - Then:
    ///    - The two results are the same for every pair
    ///
    func testCodeDeliveryDetailsEqualityTable() {
        let values = Self.deliveryDetails
        let engineValues = values.map { EngineCodeDeliveryDetails($0) }
        for (lhsIndex, lhs) in values.enumerated() {
            for (rhsIndex, rhs) in values.enumerated() {
                XCTAssertEqual(
                    engineValues[lhsIndex] == engineValues[rhsIndex],
                    conformanceEqual(lhs, rhs),
                    "\(lhs) vs \(rhs)"
                )
            }
        }
    }
}
