//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

// Test-only conversions for the challenge record: the fake engine keeps client steps, and saves them as
// the live engine would. Production maps only engine steps to saved ones, since only the engine's machine is saved.

extension EngineSignInStep {

    /// The engine step a client step mirrors, case for case: the inverse of `AuthClientSignInStep.init(_:)`.
    init(client step: AuthClientSignInStep) {
        switch step {
        case .confirmSignInWithSMSMFACode(let details, let info):
            self = .confirmSignInWithSMSMFACode(EngineCodeDeliveryDetails(client: details), info)
        case .confirmSignInWithCustomChallenge(let info):
            self = .confirmSignInWithCustomChallenge(info)
        case .confirmSignInWithNewPassword(let info):
            self = .confirmSignInWithNewPassword(info)
        case .confirmSignInWithPassword:
            self = .confirmSignInWithPassword
        case .confirmSignInWithTOTPCode:
            self = .confirmSignInWithTOTPCode
        case .continueSignInWithTOTPSetup(let details):
            self = .continueSignInWithTOTPSetup(EngineTOTPSetupDetails(sharedSecret: details.sharedSecret, username: details.username))
        case .continueSignInWithMFASelection(let types):
            self = .continueSignInWithMFASelection(Set(types.map(EngineMFAType.init(client:))))
        case .continueSignInWithEmailMFASetup:
            self = .continueSignInWithEmailMFASetup
        case .continueSignInWithMFASetupSelection(let types):
            self = .continueSignInWithMFASetupSelection(Set(types.map(EngineMFAType.init(client:))))
        case .confirmSignInWithOTP(let details):
            self = .confirmSignInWithOTP(EngineCodeDeliveryDetails(client: details))
        case .continueSignInWithFirstFactorSelection(let factors):
            self = .continueSignInWithFirstFactorSelection(Set(factors.map(EngineAuthFactorType.init)))
        case .resetPassword(let info):
            self = .resetPassword(info)
        case .confirmSignUp(let info):
            self = .confirmSignUp(info)
        case .done:
            self = .done
        }
    }
}

extension EngineMFAType {
    init(client type: AuthClientMFAType) {
        switch type {
        case .sms: self = .sms
        case .totp: self = .totp
        case .email: self = .email
        }
    }
}

extension EngineCodeDeliveryDetails {
    init(client details: AuthClientCodeDeliveryDetails) {
        let destination: EngineDeliveryDestination
        switch details.destination {
        case .email(let value): destination = .email(value)
        case .phone(let value): destination = .phone(value)
        case .sms(let value): destination = .sms(value)
        case .unknown(let value): destination = .unknown(value)
        }
        self.init(destination: destination, attributeKey: details.attributeKey?.cognitoName)
    }
}

extension ChallengeRecord.State {

    /// A saved sign-in waiting on `step`, as the live engine saves one: a TOTP setup as `.totpSetup`, any other
    /// answerable step as `.challenge` for `username` with `session`; `nil` for `confirmSignUp`, `resetPassword`
    /// and `done`, which the live engine does not save.
    static func fake(
        _ step: AuthClientSignInStep,
        session: String = "fake-session",
        username: String = "alice",
        signInMethod: ChallengeRecord.SignInMethod = .init(authFlow: "userSRP")
    ) -> ChallengeRecord.State? {
        if case .continueSignInWithTOTPSetup(let details) = step {
            return .totpSetup(ChallengeRecord.TOTPSetup(
                secretCode: details.sharedSecret,
                session: session,
                username: details.username,
                signInUsername: username,
                signInMethod: signInMethod
            ))
        }
        guard let saved = ChallengeRecord.Step(EngineSignInStep(client: step)) else {
            return nil
        }
        return .challenge(ChallengeRecord.Challenge(
            challengeName: "FAKE_CHALLENGE",
            availableChallenges: [],
            username: username,
            inputUsername: nil,
            session: session,
            parameters: nil,
            signInMethod: signInMethod,
            step: saved
        ))
    }

    /// The client step a saved sign-in reports, as the live engine resumes it.
    var fakeResumedStep: AuthClientSignInStep? {
        switch self {
        case .challenge(let challenge):
            return EngineSignInStep(challenge.step).map(AuthClientSignInStep.init)
        case .totpSetup(let setup):
            return .continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails(sharedSecret: setup.secretCode, username: setup.username))
        }
    }

    /// The username a resumed attempt signs in.
    var fakeUsername: String {
        switch self {
        case .challenge(let challenge): return challenge.username
        case .totpSetup(let setup): return setup.signInUsername ?? setup.username
        }
    }
}

extension SessionRecordStore {

    /// Stores `record` as `sessionId`'s challenge record, as bytes, bypassing `writeChallenge`'s `createdAt` rule.
    func putChallenge(_ record: ChallengeRecord, for sessionId: SessionID) throws {
        try keychain.set(record.encoded(), key: challengeAccount(for: sessionId))
    }

    /// Stores raw bytes as `sessionId`'s challenge record.
    func putChallengeBytes(_ data: Data, for sessionId: SessionID) throws {
        try keychain.set(data, key: challengeAccount(for: sessionId))
    }

    /// `sessionId`'s challenge record, if readable.
    func storedChallenge(_ sessionId: SessionID) throws -> ChallengeRecord? {
        guard case .record(let record) = try readChallenge(sessionId) else {
            return nil
        }
        return record
    }
}
