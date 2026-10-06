//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// A sign-in stopped on a challenge: its machine, retained until the sign-in completes, fails terminally, is
/// superseded or is cancelled. The step is the last one it reported.
struct SignInAttempt: Sendable {
    let operation: EngineOperation
    let step: AuthClientSignInStep
    /// The core's sign-in epoch the attempt belongs to: a cancel for a later epoch leaves it alone.
    let epoch: UInt64
    /// The window the sign-in was given, which a `"WEB_AUTHN"` answer without one of its own uses.
    var webAuthnAnchor: EnginePresentationAnchorBox?
}

/// What one sign-in step reached.
enum SignInStepOutcome: Sendable {
    /// Signed in: the payload to commit.
    case done(Data)
    /// Waiting on the user; the machine is kept as the pending attempt.
    case challenge(AuthClientSignInStep, EngineOperation)
}

/// A sign-in step's failure, and whether the pending attempt survives it (the seam's confirm contract).
struct SignInStepFailure: Error {
    let error: Error
    let keepsAttempt: Bool
    /// Tokens Cognito issued before the step failed (the user pool signed in, then the identity pool step
    /// failed), for the engine to revoke so no valid refresh token is orphaned.
    var issued: Data?
}

/// The engine's sign-in steps, ported from the plugin's task layer: `AWSAuthSignInTask.doSignIn`,
/// `AWSAuthConfirmSignInTask.execute` and `analyzeCurrentStateAndCreateEvent`, and the glue half of
/// `UserPoolSignInHelper.checkNextStep`. Each runs over one operation's machine; none touches the engine's
/// state, so the actor only records what they return.
enum LiveSignInSteps {

    // MARK: Sign-in

    /// Starts a sign-in on `operation`, a fresh one the engine built (seeded with a guest payload, or with
    /// nothing), so the engine can reach its machine to cancel it.
    static func signIn(
        _ request: EngineSignInRequest,
        on operation: EngineOperation,
        resources: EngineResources
    ) async throws -> SignInStepOutcome {
        let flow = request.authFlowType.map(EngineAuthFlowType.init)
            ?? resources.authConfiguration.getUserPoolConfiguration()?.authFlowType
            ?? .userSRP
        try await operation.configure(resources.authConfiguration)
        await operation.send(AuthenticationEvent(eventType: .signInRequested(SignInEventData(
            username: request.username,
            password: request.password,
            clientMetadata: request.clientMetadata,
            signInMethod: .apiBased(flow)
        ))))
        return try await awaitStep(on: operation, confirming: false)
    }

    // MARK: Confirmation

    /// Answers the retained attempt's challenge, choosing the event from the state it is in.
    static func confirm(
        _ request: EngineConfirmSignInRequest,
        attempt: SignInAttempt
    ) async throws -> SignInStepOutcome {
        let operation = attempt.operation
        let state = await operation.authMachine.currentState
        switch try confirmation(for: state, answering: eventData(for: request)) {
        case .alreadySignedIn:
            break
        case .send(let event):
            await operation.send(event)
        }
        return try await awaitStep(on: operation, confirming: true)
    }

    /// What answering the challenge means in the retained machine's state.
    enum Confirmation {
        /// The machine already signed in: send nothing, and read the result.
        case alreadySignedIn
        case send(StateMachineEvent)
    }

    /// The plugin's `analyzeCurrentStateAndCreateEvent` (`AWSAuthConfirmSignInTask.swift:95-165`). The two
    /// selection validations it runs first are the core's (`SessionCore.validate`), before the engine is
    /// called. The plugin's WebAuthn retry (`signingInWithWebAuthn(.error)`) has no arm, deliberately: a
    /// failed WebAuthn step drops the attempt, so no attempt is ever
    /// retained in that state, and a new sign-in starts over.
    static func confirmation(for state: AuthState, answering data: ConfirmSignInEventData) throws -> Confirmation {
        guard case .configured(let authentication, _, _) = state else {
            throw dropping(noSignInInProgress())
        }
        if case .signedIn = authentication {
            return .alreadySignedIn
        }
        guard case .signingIn(let signInState) = authentication else {
            throw dropping(noSignInInProgress())
        }
        switch signInState {
        case .resolvingChallenge(let challengeState, _, _):
            switch challengeState {
            case .waitingForAnswer, .error:
                return .send(SignInChallengeEvent(eventType: .verifyChallengeAnswer(data)))
            default:
                throw dropping(noSignInInProgress())
            }
        case .resolvingTOTPSetup(let setupState, _):
            switch setupState {
            case .waitingForAnswer, .error:
                return .send(SetUpTOTPEvent(eventType: .verifyChallengeAnswer(data)))
            default:
                throw dropping(noSignInInProgress())
            }
        case .signingInViaMigrateAuth(let migrateState, _):
            guard case .error = migrateState else {
                throw dropping(noSignInInProgress())
            }
            throw dropping(restartRequired())
        case .signingInWithSRP(let srpState, _):
            guard case .error = srpState else {
                throw dropping(noSignInInProgress())
            }
            throw dropping(restartRequired())
        default:
            throw dropping(noSignInInProgress())
        }
    }

    /// The plugin's `createConfirmSignInEventData`: the attributes gain the `userAttributes.` prefix
    /// `RespondToAuthChallenge` expects. The event carries no presentation anchor: a WebAuthn
    /// ceremony gets its window from the operation's ceremony slot.
    static func eventData(for request: EngineConfirmSignInRequest) -> ConfirmSignInEventData {
        ConfirmSignInEventData(
            answer: request.challengeResponse,
            attributes: Dictionary(uniqueKeysWithValues: request.userAttributes.map { (attributePrefix + $0.key, $0.value) }),
            metadata: request.clientMetadata.isEmpty ? nil : request.clientMetadata,
            friendlyDeviceName: request.friendlyDeviceName,
            presentationAnchor: nil
        )
    }

    /// `AuthPluginConstants.cognitoIdentityUserUserAttributePrefix`, which is internal to the engine.
    static let attributePrefix = "userAttributes."

    // MARK: Waiting for the step's end

    /// Waits for the sign-in to finish or stop on a challenge. If the task is cancelled meanwhile
    /// (`cancelPendingSignIn`), it returns the tokens Cognito already issued, for the core to revoke, or
    /// throws `CancellationError`.
    static func awaitStep(on operation: EngineOperation, confirming: Bool) async throws -> SignInStepOutcome {
        do {
            return try await operation.firstState { state in
                try progress(of: state, operation: operation, confirming: confirming)
            }
        } catch is CancellationError {
            if let issued = await issuedPayload(on: operation) {
                return .done(issued)
            }
            await cancelIfSigningIn(operation)
            throw CancellationError()
        } catch let failure as SignInStepFailure {
            if !failure.keepsAttempt {
                await cancelIfSigningIn(operation)
            }
            throw failure
        }
    }

    /// One state of a sign-in step: `nil` to keep waiting, a result, or a thrown `SignInStepFailure`. The
    /// plugin's two listener loops (`AWSAuthSignInTask.doSignIn`, `AWSAuthConfirmSignInTask.execute`).
    static func progress(
        of state: AuthState,
        operation: EngineOperation,
        confirming: Bool
    ) throws -> SignInStepOutcome? {
        guard case .configured(let authentication, let authorization, _) = state else {
            return nil
        }
        switch authentication {
        case .signedIn(let signedInData):
            switch authorization {
            case .sessionEstablished(let credentials):
                do {
                    return try .done(operation.payload(establishing: credentials))
                } catch {
                    throw dropping(error)
                }
            case .error(let error):
                // The user pool signed in, then the identity pool step failed: the plugin throws, and so do
                // we, but the issued tokens go back for the engine to revoke.
                throw SignInStepFailure(
                    error: map(error.engineError, confirming: confirming, challengeRejected: false),
                    keepsAttempt: false,
                    issued: try? CredentialSlot.encode(.userPoolOnly(signedInData: signedInData))
                )
            default:
                return nil
            }
        case .error(let error):
            throw dropping(map(error.engineError, confirming: confirming, challengeRejected: false))
        case .signingIn(let signInState):
            return try step(
                in: signInState,
                confirming: confirming,
                challengeRejected: operation.tokenTap.lastChallengeRejectedByUserPool
            ).map { .challenge($0, operation) }
        case .notConfigured:
            throw dropping(AuthClientError.configuration(
                "UserPool configuration is missing",
                "Configure the user pool in AuthClientConfiguration."
            ))
        case .signedOut, .signingOut, .deletingUser, .federatedToIdentityPool, .federatingToIdentityPool,
             .clearingFederation:
            // Only a cancel moves a sign-in here; the plugin's confirm loop throws for any of them.
            if confirming {
                throw dropping(noSignInInProgress())
            }
            return nil
        case .configured:
            return nil
        }
    }

    /// The step a sign-in state waits on, `nil` while it is still working, or the failure it reached. The
    /// glue half of `UserPoolSignInHelper.checkNextStep`.
    /// `challengeRejected` says whether the latest answer was rejected with the user pool's
    /// `NotAuthorizedException`, which an expired challenge needs besides its message.
    static func step(in signInState: SignInState, confirming: Bool, challengeRejected: Bool = false) throws -> AuthClientSignInStep? {
        switch signInState {
        case .signingInWithSRP(let srpState, _):
            if case .error(let error) = srpState {
                return try failed(error, retryable: false, confirming: confirming, challengeRejected: challengeRejected)
            }
        case .signingInWithSRPCustom(let srpState, _):
            if case .error(let error) = srpState {
                return try failed(error, retryable: false, confirming: confirming, challengeRejected: challengeRejected)
            }
        case .signingInViaMigrateAuth(let migrateState, _):
            if case .error(let error) = migrateState {
                return try failed(error, retryable: false, confirming: confirming, challengeRejected: challengeRejected)
            }
        case .signingInWithCustom(let customState, _):
            if case .error(let error) = customState {
                return try failed(error, retryable: false, confirming: confirming, challengeRejected: challengeRejected)
            }
        case .signingInWithHostedUI(let hostedUIState):
            if case .error(let error) = hostedUIState {
                return try failed(error, retryable: false, confirming: confirming, challengeRejected: challengeRejected)
            }
        case .resolvingChallenge(let challengeState, _, _):
            switch challengeState {
            case .error(_, _, let error, _):
                return try failed(error, retryable: true, confirming: confirming, challengeRejected: challengeRejected)
            case .waitingForAnswer(_, _, let step):
                return AuthClientSignInStep(step)
            default:
                break
            }
        case .resolvingTOTPSetup(let setupState, _):
            switch setupState {
            case .error(_, let error):
                return try failed(error, retryable: true, confirming: confirming, challengeRejected: challengeRejected)
            case .waitingForAnswer(let setup):
                return .continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails(
                    sharedSecret: setup.secretCode,
                    username: setup.username
                ))
            default:
                break
            }
        case .signingInWithWebAuthn(let webAuthnState):
            // The ceremony runs as the operation's slot says: over the step's window, under the sheet lease,
            // or refused without presenting when the step has no window. A failure drops
            // the attempt; success reaches `.signedIn` like any other factor.
            if case .error(let error, _) = webAuthnState {
                throw dropping(webAuthnFailure(error, confirming: confirming, challengeRejected: challengeRejected))
            }
        case .notStarted, .signingInWithUserAuth, .autoSigningIn, .confirmingDevice, .resolvingDeviceSrpa,
             .signedIn, .error:
            break
        }
        return nil
    }

    /// The plugin's `validateError`: an unconfirmed user and a required password reset are steps; anything
    /// else is thrown. A failure inside a challenge or a TOTP setup keeps the attempt on the confirm path, so
    /// the user can answer again, unless the challenge session itself has expired.
    private static func failed(
        _ error: SignInError,
        retryable: Bool,
        confirming: Bool,
        challengeRejected: Bool
    ) throws -> AuthClientSignInStep {
        if error.isUserNotConfirmed {
            return .confirmSignUp(nil)
        }
        if error.isResetPassword {
            return .resetPassword(nil)
        }
        let mapped = map(error.engineError, confirming: confirming, challengeRejected: challengeRejected)
        let expired: Bool
        if case .challengeExpired = mapped {
            expired = true
        } else {
            expired = false
        }
        throw SignInStepFailure(error: mapped, keepsAttempt: confirming && retryable && !expired)
    }

    /// A failed WebAuthn step, as the caller sees it. The sheet lease's own `CancellationError` (a sign-out,
    /// or the caller, stopped the ceremony) is cancellation, which the core then names; anything else is the
    /// mapped engine error, where a ceremony failure is never `.service` (`AuthClientError(engine:)`).
    static func webAuthnFailure(_ error: SignInError, confirming: Bool, challengeRejected: Bool) -> Error {
        let engineError = error.engineError
        if case .service(_, _, let underlying) = engineError, underlying is CancellationError {
            return CancellationError()
        }
        return map(engineError, confirming: confirming, challengeRejected: challengeRejected)
    }

    /// Whether `answer` selects WebAuthn at `step`, which needs a presentation anchor.
    static func selectsWebAuthn(_ answer: String, at step: AuthClientSignInStep) -> Bool {
        guard case .continueSignInWithFirstFactorSelection = step else {
            return false
        }
        return answer == "WEB_AUTHN"
    }

    private static func map(_ error: EngineAuthError, confirming: Bool, challengeRejected: Bool) -> AuthClientError {
        confirming
            ? AuthClientError(engineConfirmingSignIn: error, rejectedByUserPool: challengeRejected)
            : AuthClientError(engine: error)
    }

    // MARK: Cancellation

    /// The tokens a cancelled step already holds: the established credentials, or, if Cognito issued the
    /// user pool tokens but the identity pool step had not finished, the user pool tokens alone. Either is
    /// enough for the core to revoke the refresh token.
    static func issuedPayload(on operation: EngineOperation) async -> Data? {
        guard case .configured(.signedIn(let signedInData), let authorization, _) = await operation.authMachine.currentState else {
            return nil
        }
        let credentials: AmplifyCredentials
        if case .sessionEstablished(let established) = authorization {
            credentials = established
        } else {
            credentials = .userPoolOnly(signedInData: signedInData)
        }
        return try? CredentialSlot.encode(credentials)
    }

    /// Stops a machine that is still signing in, so its remaining effects do nothing: the plugin's
    /// `sendCancelSignInEvent`. A machine that already signed in is left alone: `.cancelSignIn` would sign it
    /// out, and revoking is the core's decision.
    ///
    /// The event is sent from an unstructured task: `StateMachine.send` drops an event sent from a cancelled
    /// task, and this runs from cancelled steps too. The cancel check and the step's own sends are ordered
    /// on the machine's actor: a step cancelled before it sends `.signInRequested` has that send dropped,
    /// and one that already sent it is `.signingIn` here.
    static func cancelIfSigningIn(_ operation: EngineOperation) async {
        await Task {
            guard case .configured(.signingIn, _, _) = await operation.authMachine.currentState else {
                return
            }
            await operation.send(AuthenticationEvent(eventType: .cancelSignIn))
        }.value
    }

    // MARK: Errors

    static func dropping(_ error: Error) -> SignInStepFailure {
        SignInStepFailure(error: error, keepsAttempt: false)
    }

    static func noSignInInProgress() -> AuthClientError {
        .invalidState("There is no sign-in in progress for this session", "Call signIn first.")
    }

    static func restartRequired() -> AuthClientError {
        .invalidState(
            "Cannot use confirmSignIn in the current state. Call signIn to start the sign-in again.",
            "Call signIn to start a new sign-in."
        )
    }
}
