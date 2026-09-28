//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

// The challenge record (`ChallengeRecord`) to and from the engine's sign-in states.
//
// Exactly two machine states can be answered by `confirmSignIn` (`LiveSignInSteps.confirmation(for:)`), so exactly
// two are saved and resumed:
// - `SignInState.resolvingChallenge(.waitingForAnswer | .error, …)`, as `ChallengeRecord.State.challenge`;
// - `SignInState.resolvingTOTPSetup(.waitingForAnswer | .error(data?, _), …)`, as `.totpSetup`.
// Every other state is not saved: an SRP or migrate-auth error (`confirmSignUp`, `resetPassword`, which answer
// "restart"), a step in flight, a WebAuthn ceremony, a hosted-UI sign-in. A wrong answer's `.error` sub-state is
// saved as `.waitingForAnswer` with the same session: resumed, the user answers again.
//
// **The password is never saved.** `resolvingTOTPSetup` carries the sign-in's whole `SignInEventData`, password
// included, and that type's `Codable` encodes it. Nothing reads it past a challenge (only `InitiateUserAuth`, the SRP
// resolver and the migrate-auth resolver do, and they all run before one), so the TOTP setup is saved with the
// username and sign-in method only, and resumed with `password: nil`. Nor is the `signIn` call's client metadata:
// the resumed confirmation sends its own.
extension ChallengeRecord.State {

    /// The saved form of a sign-in waiting on the user, or `nil` if its state is not one `confirmSignIn` answers or
    /// cannot be saved (a hosted-UI sign-in method, a step with no saved form).
    init?(_ state: AuthState) {
        guard case .configured(.signingIn(let signInState), _, _) = state else {
            return nil
        }
        switch signInState {
        case .resolvingChallenge(let challengeState, _, _):
            let challenge: RespondToAuthChallenge
            let method: SignInMethod
            let step: EngineSignInStep
            switch challengeState {
            case .waitingForAnswer(let waiting, let waitingMethod, let waitingStep):
                (challenge, method, step) = (waiting, waitingMethod, waitingStep)
            case .error(let failed, let failedMethod, _, let failedStep):
                (challenge, method, step) = (failed, failedMethod, failedStep)
            default:
                return nil
            }
            guard let savedMethod = ChallengeRecord.SignInMethod(method),
                  let savedStep = ChallengeRecord.Step(step) else {
                return nil
            }
            self = .challenge(ChallengeRecord.Challenge(
                challengeName: challenge.challenge.rawValue,
                availableChallenges: challenge.availableChallenges.map(\.rawValue),
                username: challenge.username,
                inputUsername: challenge.inputUsername,
                session: challenge.session,
                parameters: challenge.parameters,
                signInMethod: savedMethod,
                step: savedStep
            ))
        case .resolvingTOTPSetup(let setupState, let eventData):
            let setup: SignInTOTPSetupData
            switch setupState {
            case .waitingForAnswer(let waiting):
                setup = waiting
            case .error(let failed?, _):
                setup = failed
            default:
                return nil
            }
            guard let savedMethod = ChallengeRecord.SignInMethod(eventData.signInMethod) else {
                return nil
            }
            self = .totpSetup(ChallengeRecord.TOTPSetup(
                secretCode: setup.secretCode,
                session: setup.session,
                username: setup.username,
                signInUsername: eventData.username,
                signInMethod: savedMethod
            ))
        default:
            return nil
        }
    }

    /// The machine state a resumed sign-in starts in, and the step it reports; `nil` if this build cannot resume the
    /// record (a spelling it does not know, a factor this platform lacks).
    ///
    /// The authorization state is `.configured`: a completed sign-in's `signInCompleted` starts the session fetch
    /// from any authorization state, and the guest identity, if the session is a guest, is in the operation's
    /// credential slot (`confirmSignIn`'s reseed), as for a sign-in that never stopped.
    var resumedState: (AuthState, AuthClientSignInStep)? {
        switch self {
        case .challenge(let saved):
            guard let method = SignInMethod(saved.signInMethod), let step = EngineSignInStep(saved.step) else {
                return nil
            }
            let challenge = RespondToAuthChallenge(
                challenge: Self.challengeName(saved.challengeName),
                availableChallenges: saved.availableChallenges.map(Self.challengeName),
                username: saved.username,
                session: saved.session,
                parameters: saved.parameters,
                inputUsername: saved.inputUsername
            )
            let signIn = SignInState.resolvingChallenge(
                .waitingForAnswer(challenge, method, step),
                challenge.challenge.authChallengeType,
                method
            )
            return (.configured(.signingIn(signIn), .configured, .notStarted), AuthClientSignInStep(step))
        case .totpSetup(let saved):
            guard let method = SignInMethod(saved.signInMethod) else {
                return nil
            }
            let setup = SignInTOTPSetupData(secretCode: saved.secretCode, session: saved.session, username: saved.username)
            let eventData = SignInEventData(username: saved.signInUsername, password: nil, signInMethod: method)
            let signIn = SignInState.resolvingTOTPSetup(.waitingForAnswer(setup), eventData)
            let step = AuthClientSignInStep.continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails(
                sharedSecret: saved.secretCode,
                username: saved.username
            ))
            return (.configured(.signingIn(signIn), .configured, .notStarted), step)
        }
    }
}

extension ChallengeRecord.State {

    /// Cognito's spelling as the SDK's type, a spelling it does not know as `sdkUnknown`, as the SDK decodes one.
    static func challengeName(_ spelling: String) -> CognitoIdentityProviderClientTypes.ChallengeNameType {
        CognitoIdentityProviderClientTypes.ChallengeNameType(rawValue: spelling) ?? .sdkUnknown(spelling)
    }
}

// MARK: - Sign-in method

extension ChallengeRecord.SignInMethod {

    /// `nil` for a hosted-UI sign-in, which never stops on a challenge `confirmSignIn` answers.
    init?(_ method: SignInMethod) {
        guard case .apiBased(let flow) = method else {
            return nil
        }
        switch flow {
        case .userSRP: self.init(authFlow: "userSRP")
        case .custom: self.init(authFlow: "custom")
        case .customWithSRP: self.init(authFlow: "customWithSRP")
        case .customWithoutSRP: self.init(authFlow: "customWithoutSRP")
        case .userPassword: self.init(authFlow: "userPassword")
        case .userAuth(let preferred): self.init(authFlow: "userAuth", preferredFirstFactor: preferred?.rawValue)
        }
    }
}

extension SignInMethod {

    init?(_ saved: ChallengeRecord.SignInMethod) {
        let flow: EngineAuthFlowType
        switch saved.authFlow {
        case "userSRP": flow = .userSRP
        case "custom": flow = .custom
        case "customWithSRP": flow = .customWithSRP
        case "customWithoutSRP": flow = .customWithoutSRP
        case "userPassword": flow = .userPassword
        case "userAuth":
            if let preferred = saved.preferredFirstFactor {
                guard let factor = EngineAuthFactorType(rawValue: preferred) else {
                    return nil
                }
                flow = .userAuth(preferredFirstFactor: factor)
            } else {
                flow = .userAuth(preferredFirstFactor: nil)
            }
        default:
            return nil
        }
        self = .apiBased(flow)
    }
}

// MARK: - Step

extension ChallengeRecord.Step {

    /// `nil` for a step no challenge state waits on (`continueSignInWithTOTPSetup` is the TOTP setup's own state;
    /// `resetPassword`, `confirmSignUp` and `done` are not answered by `confirmSignIn`).
    init?(_ step: EngineSignInStep) {
        switch step {
        case .confirmSignInWithSMSMFACode(let delivery, let info):
            self.init(kind: .confirmSignInWithSMSMFACode, codeDelivery: .init(delivery), additionalInfo: info)
        case .confirmSignInWithCustomChallenge(let info):
            self.init(kind: .confirmSignInWithCustomChallenge, additionalInfo: info)
        case .confirmSignInWithNewPassword(let info):
            self.init(kind: .confirmSignInWithNewPassword, additionalInfo: info)
        case .confirmSignInWithPassword:
            self.init(kind: .confirmSignInWithPassword)
        case .confirmSignInWithTOTPCode:
            self.init(kind: .confirmSignInWithTOTPCode)
        case .continueSignInWithMFASelection(let types):
            self.init(kind: .continueSignInWithMFASelection, mfaTypes: types.map(\.rawValue).sorted())
        case .continueSignInWithEmailMFASetup:
            self.init(kind: .continueSignInWithEmailMFASetup)
        case .continueSignInWithMFASetupSelection(let types):
            self.init(kind: .continueSignInWithMFASetupSelection, mfaTypes: types.map(\.rawValue).sorted())
        case .confirmSignInWithOTP(let delivery):
            self.init(kind: .confirmSignInWithOTP, codeDelivery: .init(delivery))
        case .continueSignInWithFirstFactorSelection(let factors):
            self.init(kind: .continueSignInWithFirstFactorSelection, factorTypes: factors.map(\.rawValue).sorted())
        case .continueSignInWithTOTPSetup, .resetPassword, .confirmSignUp, .done:
            return nil
        }
    }
}

extension EngineSignInStep {

    /// `nil` if a saved payload is missing, or names a type this build does not know.
    init?(_ saved: ChallengeRecord.Step) {
        switch saved.kind {
        case .confirmSignInWithSMSMFACode:
            guard let delivery = saved.codeDelivery.flatMap(EngineCodeDeliveryDetails.init) else {
                return nil
            }
            self = .confirmSignInWithSMSMFACode(delivery, saved.additionalInfo)
        case .confirmSignInWithCustomChallenge:
            self = .confirmSignInWithCustomChallenge(saved.additionalInfo)
        case .confirmSignInWithNewPassword:
            self = .confirmSignInWithNewPassword(saved.additionalInfo)
        case .confirmSignInWithPassword:
            self = .confirmSignInWithPassword
        case .confirmSignInWithTOTPCode:
            self = .confirmSignInWithTOTPCode
        case .continueSignInWithMFASelection:
            guard let types = Self.mfaTypes(saved.mfaTypes) else {
                return nil
            }
            self = .continueSignInWithMFASelection(types)
        case .continueSignInWithEmailMFASetup:
            self = .continueSignInWithEmailMFASetup
        case .continueSignInWithMFASetupSelection:
            guard let types = Self.mfaTypes(saved.mfaTypes) else {
                return nil
            }
            self = .continueSignInWithMFASetupSelection(types)
        case .confirmSignInWithOTP:
            guard let delivery = saved.codeDelivery.flatMap(EngineCodeDeliveryDetails.init) else {
                return nil
            }
            self = .confirmSignInWithOTP(delivery)
        case .continueSignInWithFirstFactorSelection:
            guard let spellings = saved.factorTypes else {
                return nil
            }
            var factors = Set<EngineAuthFactorType>()
            for spelling in spellings {
                guard let factor = EngineAuthFactorType(rawValue: spelling) else {
                    return nil
                }
                factors.insert(factor)
            }
            self = .continueSignInWithFirstFactorSelection(factors)
        }
    }

    private static func mfaTypes(_ spellings: [String]?) -> Set<EngineMFAType>? {
        guard let spellings else {
            return nil
        }
        var types = Set<EngineMFAType>()
        for spelling in spellings {
            guard let type = EngineMFAType(rawValue: spelling) else {
                return nil
            }
            types.insert(type)
        }
        return types
    }
}

// MARK: - Code delivery

extension ChallengeRecord.CodeDelivery {

    init(_ details: EngineCodeDeliveryDetails) {
        switch details.destination {
        case .email(let value): self.init(medium: "email", destination: value, attributeKey: details.attributeKey)
        case .phone(let value): self.init(medium: "phone", destination: value, attributeKey: details.attributeKey)
        case .sms(let value): self.init(medium: "sms", destination: value, attributeKey: details.attributeKey)
        case .unknown(let value): self.init(medium: "unknown", destination: value, attributeKey: details.attributeKey)
        }
    }
}

extension EngineCodeDeliveryDetails {

    init?(_ saved: ChallengeRecord.CodeDelivery) {
        let destination: EngineDeliveryDestination
        switch saved.medium {
        case "email": destination = .email(saved.destination)
        case "phone": destination = .phone(saved.destination)
        case "sms": destination = .sms(saved.destination)
        case "unknown": destination = .unknown(saved.destination)
        default: return nil
        }
        self.init(destination: destination, attributeKey: saved.attributeKey)
    }
}
