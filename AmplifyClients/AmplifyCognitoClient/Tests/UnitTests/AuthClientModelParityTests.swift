//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Pins the client's mirrored enums to Amplify core's case lists.
///
/// This target cannot import Amplify (the client must not depend on it), so Amplify core's case
/// lists are transcribed below, each citing the file and lines it came from in Amplify core. Each client
/// enum is then enumerated through an exhaustive `switch` with no `default`, so:
///
/// - a case added to the client breaks compilation here until the pinned list is revisited, and
/// - a case added to Amplify core is caught at review against the plugin bridge's mapping table.
final class AuthClientModelParityTests: XCTestCase {

    // MARK: - AuthClientSignInStep

    /// Transcribed from `Amplify/Categories/Auth/Models/AuthSignInStep.swift`, lines 22-76.
    static let amplifySignInStepCases = [
        "confirmSignInWithSMSMFACode", // line 22
        "confirmSignInWithCustomChallenge", // line 26
        "confirmSignInWithNewPassword", // line 30
        "confirmSignInWithPassword", // line 34
        "confirmSignInWithTOTPCode", // line 39
        "continueSignInWithTOTPSetup", // line 43
        "continueSignInWithMFASelection", // line 47
        "continueSignInWithEmailMFASetup", // line 51
        "continueSignInWithMFASetupSelection", // line 55
        "confirmSignInWithOTP", // line 60
        "continueSignInWithFirstFactorSelection", // line 64
        "resetPassword", // line 68
        "confirmSignUp", // line 72
        "done" // line 76
    ]

    /// One value of every `AuthClientSignInStep` case.
    static let clientSignInSteps: [AuthClientSignInStep] = {
        let delivery = AuthClientCodeDeliveryDetails(destination: .email("a***"))
        return [
            .confirmSignInWithSMSMFACode(delivery, nil),
            .confirmSignInWithCustomChallenge(nil),
            .confirmSignInWithNewPassword(nil),
            .confirmSignInWithPassword,
            .confirmSignInWithTOTPCode,
            .continueSignInWithTOTPSetup(.init(sharedSecret: "s", username: "u")),
            .continueSignInWithMFASelection([.totp]),
            .continueSignInWithEmailMFASetup,
            .continueSignInWithMFASetupSelection([.email]),
            .confirmSignInWithOTP(delivery),
            .continueSignInWithFirstFactorSelection([.password]),
            .resetPassword(nil),
            .confirmSignUp(nil),
            .done
        ]
    }()

    /// Exhaustive on purpose: no `default`, so a new client case does not compile until it is named.
    static func name(of step: AuthClientSignInStep) -> String {
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

    /// - Given: Amplify core's `AuthSignInStep` case list, pinned from source, and one value of
    ///   every `AuthClientSignInStep` case
    /// - When: the client values are named through an exhaustive switch
    /// - Then:
    ///    - the client has exactly 14 cases, named exactly as Amplify's, in the same order, and
    ///      no two sample values are equal
    func testSignInStepHasExactlyAmplifysCases() {
        let names = Self.clientSignInSteps.map(Self.name(of:))

        XCTAssertEqual(Self.amplifySignInStepCases.count, 14)
        XCTAssertEqual(names, Self.amplifySignInStepCases)
        for (index, step) in Self.clientSignInSteps.enumerated() {
            for other in Self.clientSignInSteps[(index + 1)...] {
                XCTAssertNotEqual(step, other)
            }
        }
    }

    // MARK: - AuthClientMFAType

    /// Transcribed from `Amplify/Categories/Auth/Models/MFAType.swift`, lines 11-17.
    static let amplifyMFATypeCases = ["sms", "totp", "email"]

    /// - Given: Amplify core's `MFAType` case list, pinned from source
    /// - When: every `AuthClientMFAType` case is named through an exhaustive switch
    /// - Then:
    ///    - the names match Amplify's exactly
    func testMFATypeHasExactlyAmplifysCases() {
        func name(_ type: AuthClientMFAType) -> String {
            switch type {
            case .sms: return "sms"
            case .totp: return "totp"
            case .email: return "email"
            }
        }
        let all: [AuthClientMFAType] = [.sms, .totp, .email]
        XCTAssertEqual(all.map(name), Self.amplifyMFATypeCases)
    }

    // MARK: - AuthClientFactorType

    /// Transcribed from `Amplify/Categories/Auth/Models/AuthFactorType.swift`, lines 11-25.
    /// `webAuthn` (line 25) exists only under `#if os(iOS) || os(macOS) || os(visionOS)`.
    static let amplifyFactorTypeCases: [String] = {
        var cases = ["password", "passwordSRP", "smsOTP", "emailOTP"]
        #if os(iOS) || os(macOS) || os(visionOS)
        cases.append("webAuthn")
        #endif
        return cases
    }()

    /// - Given: Amplify core's `AuthFactorType` case list for this platform, pinned from source
    /// - When: every `AuthClientFactorType` case is named through an exhaustive switch
    /// - Then:
    ///    - the names match Amplify's exactly, including the platform-conditional `webAuthn`
    func testFactorTypeHasExactlyAmplifysCases() {
        func name(_ type: AuthClientFactorType) -> String {
            switch type {
            case .password: return "password"
            case .passwordSRP: return "passwordSRP"
            case .smsOTP: return "smsOTP"
            case .emailOTP: return "emailOTP"
            #if os(iOS) || os(macOS) || os(visionOS)
            case .webAuthn: return "webAuthn"
            #endif
            }
        }
        var all: [AuthClientFactorType] = [.password, .passwordSRP, .smsOTP, .emailOTP]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            all.append(.webAuthn)
        }
        #endif
        let expected: [String]
        if all.count == Self.amplifyFactorTypeCases.count {
            expected = Self.amplifyFactorTypeCases
        } else {
            // An OS older than webAuthn's @available floor cannot construct the case at all.
            expected = Array(Self.amplifyFactorTypeCases.prefix(all.count))
        }
        XCTAssertEqual(all.map(name), expected)
    }

    // MARK: - AuthClientDeliveryDestination

    /// Transcribed from `Amplify/Categories/Auth/Models/DeliveryDestination.swift`, lines 14-23.
    static let amplifyDeliveryDestinationCases = ["email", "phone", "sms", "unknown"]

    /// - Given: Amplify core's `DeliveryDestination` case list, pinned from source
    /// - When: every `AuthClientDeliveryDestination` case is named through an exhaustive switch
    /// - Then:
    ///    - the names match Amplify's exactly
    func testDeliveryDestinationHasExactlyAmplifysCases() {
        func name(_ destination: AuthClientDeliveryDestination) -> String {
            switch destination {
            case .email: return "email"
            case .phone: return "phone"
            case .sms: return "sms"
            case .unknown: return "unknown"
            }
        }
        let all: [AuthClientDeliveryDestination] = [.email(nil), .phone(nil), .sms(nil), .unknown(nil)]
        XCTAssertEqual(all.map(name), Self.amplifyDeliveryDestinationCases)
    }

    // MARK: - AuthClientUserAttributeKey

    /// Transcribed from `Amplify/Categories/Auth/Models/AuthUserAttribute.swift`, lines 24-87.
    static let amplifyUserAttributeKeyCases = [
        "address", "birthDate", "email", "emailVerified", "familyName", "gender", "givenName",
        "locale", "middleName", "name", "nickname", "phoneNumber", "phoneNumberVerified", "picture",
        "preferredUsername", "profile", "sub", "updatedAt", "website", "zoneInfo", "custom", "unknown"
    ]

    /// - Given: Amplify core's `AuthUserAttributeKey` case list, pinned from source
    /// - When: every `AuthClientUserAttributeKey` case is named through an exhaustive switch
    /// - Then:
    ///    - the client has exactly 22 cases, named exactly as Amplify's
    func testUserAttributeKeyHasExactlyAmplifysCases() {
        func name(_ key: AuthClientUserAttributeKey) -> String {
            switch key {
            case .address: return "address"
            case .birthDate: return "birthDate"
            case .email: return "email"
            case .emailVerified: return "emailVerified"
            case .familyName: return "familyName"
            case .gender: return "gender"
            case .givenName: return "givenName"
            case .locale: return "locale"
            case .middleName: return "middleName"
            case .name: return "name"
            case .nickname: return "nickname"
            case .phoneNumber: return "phoneNumber"
            case .phoneNumberVerified: return "phoneNumberVerified"
            case .picture: return "picture"
            case .preferredUsername: return "preferredUsername"
            case .profile: return "profile"
            case .sub: return "sub"
            case .updatedAt: return "updatedAt"
            case .website: return "website"
            case .zoneInfo: return "zoneInfo"
            case .custom: return "custom"
            case .unknown: return "unknown"
            }
        }
        let all: [AuthClientUserAttributeKey] = [
            .address, .birthDate, .email, .emailVerified, .familyName, .gender, .givenName,
            .locale, .middleName, .name, .nickname, .phoneNumber, .phoneNumberVerified, .picture,
            .preferredUsername, .profile, .sub, .updatedAt, .website, .zoneInfo, .custom("c"), .unknown("u")
        ]
        XCTAssertEqual(Self.amplifyUserAttributeKeyCases.count, 22)
        XCTAssertEqual(all.map(name), Self.amplifyUserAttributeKeyCases)
    }
}
