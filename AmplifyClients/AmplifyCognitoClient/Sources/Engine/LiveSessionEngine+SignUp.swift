//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// Sign-up, confirmation, code resend and auto sign-in, ported from the plugin's
/// `AWSAuthSignUpTask`, `AWSAuthConfirmSignUpTask`, `AWSAuthResendSignUpCodeTask` and `AWSAuthAutoSignInTask`.
///
/// Sign-up and confirmation run on a fresh operation's machine, as the plugin's run on its one machine: the
/// engine's `InitiateSignUp` and `ConfirmSignUp` actions build the requests, with the same validation data,
/// advanced-security context and analytics. Resending a code calls Cognito directly, as the plugin's task
/// does. None of them reads or writes the session's credentials.
///
/// What the plugin keeps in its one `SignUpState`, this engine keeps for its session only, in
/// `signUpState` (the seam's "Sign-up" contract). Every sign-up and confirmation moves it: to `inProgress`
/// when it starts, then to what it reached (`awaitingConfirmation`, `signedUp` or `error`), unless a newer one
/// started meanwhile. So a later sign-up or confirmation, whatever its outcome, replaces what an earlier one
/// left, and `autoSignIn` can only sign in the user of the last one, as the plugin's `AWSAuthAutoSignInTask`
/// refuses any state but `signedUp`.
///
/// `autoSignIn` runs as a sign-in step: the `beginSignIn(epoch:)` preamble, then `run(epoch:on:_:)` on an
/// operation built first.
extension LiveSessionEngine {

    /// Whether `autoSignIn` has a sign-up to complete: the last sign-up or confirmation reached `signedUp` with
    /// Cognito's session (`.completeAutoSignIn`).
    var hasAutoSignInSession: Bool {
        signUpState.autoSignInData != nil
    }

    // MARK: Sign-up

    /// Registers the user (`AWSAuthSignUpTask.doSignUp`).
    ///
    /// - Throws: Cognito's answer, mapped as the plugin maps it (`usernameExists`, `invalidPassword`, …).
    nonisolated func signUp(_ request: EngineSignUpRequest) async throws -> AuthClientSignUpResult {
        try requireUserPool()
        let data = SignUpEventData(
            username: request.username,
            clientMetadata: Self.omittedIfEmpty(request.clientMetadata),
            validationData: Self.omittedIfEmpty(request.validationData)
        )
        let attributes = request.userAttributes.map { EngineUserAttribute(key: $0.key, value: $0.value) }
        let ticket = await beginSignUpStep(data)
        let outcome: (SignUpEventData, EngineSignUpResult)
        do {
            outcome = try await Self.runSignUp(
                SignUpEvent(eventType: .initiateSignUp(data, request.password, attributes)),
                resources: resources
            )
        } catch {
            // The plugin's state moves to `.error` with the request's data, which has no session.
            await endSignUpStep(ticket, .error(data))
            throw error
        }
        let (signedUp, result) = outcome
        await endSignUpStep(ticket, LiveSignUpState(reached: result, with: signedUp))
        return AuthClientSignUpResult(result)
    }

    // MARK: Confirmation

    /// Confirms the sign-up (`AWSAuthConfirmSignUpTask.doConfirmSignUp`). It sends the Cognito session of the
    /// sign-up waiting for confirmation only when its username is this one, as the plugin does.
    ///
    /// - Throws: Cognito's answer, mapped (`codeMismatch`, `expiredCode`, …).
    nonisolated func confirmSignUp(_ request: EngineConfirmSignUpRequest) async throws -> AuthClientSignUpResult {
        try requireUserPool()
        let (ticket, data) = await beginConfirmation(request)
        let outcome: (SignUpEventData, EngineSignUpResult)
        do {
            outcome = try await Self.runSignUp(
                SignUpEvent(eventType: .confirmSignUp(data, request.confirmationCode, request.forceAliasCreation)),
                resources: resources
            )
        } catch {
            // The plugin's state moves to `.error` with this confirmation's data: a retry for the same
            // username sends the same session, and any other username none.
            await endSignUpStep(ticket, .error(data))
            throw error
        }
        let (signedUp, result) = outcome
        await endSignUpStep(ticket, .signedUp(signedUp))
        return AuthClientSignUpResult(result)
    }

    /// The confirmation's data, with the session of the sign-up waiting for it when the username matches
    /// (`sendConfirmSignUpEvent`), and the start of its step, in one actor turn so no other sign-up step
    /// moves the state in between.
    func beginConfirmation(_ request: EngineConfirmSignUpRequest) -> (UInt64, SignUpEventData) {
        let data = SignUpEventData(
            username: request.username,
            clientMetadata: Self.omittedIfEmpty(request.clientMetadata),
            session: signUpState.confirmationSession(for: request.username)
        )
        return (beginSignUpStep(data), data)
    }

    // MARK: Resending the code

    /// Sends the sign-up code again (`AWSAuthResendSignUpCodeTask.resendSignUpCode`), with the plugin's
    /// advanced-security context, analytics and secret hash.
    ///
    /// - Throws: Cognito's answer, mapped; `unknown` if Cognito answers without delivery details.
    nonisolated func resendSignUpCode(username: String, clientMetadata: [String: String]) async throws -> AuthClientCodeDeliveryDetails {
        try requireUserPool()
        let resources = resources
        guard let userPoolConfiguration = resources.authConfiguration.getUserPoolConfiguration() else {
            // `requireUserPool` has already refused this.
            throw AuthClientError.configuration(
                "UserPool configuration is missing",
                "Add a user pool to AuthClientConfiguration."
            )
        }
        // The operation's machines give the request the device records the plugin's environment reads.
        let operation = try resources.makeOperation(seed: nil)
        try await operation.configure(resources.authConfiguration)
        let environment = resources
            .makeEnvironmentFactory(credentialStore: operation.credentialStore)
            .makeAuthEnvironment(credentialsClient: CredentialStoreOperationClient(
                credentialStoreStateMachine: operation.credentialMachine
            ))
        let output: ResendConfirmationCodeOutput
        do {
            let userPoolEnvironment = environment.userPoolEnvironment
            let userPoolService = try userPoolEnvironment.cognitoUserPoolFactory()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: environment.credentialsClient
            )
            let encodedData = await CognitoUserPoolASF.encodedContext(
                username: username,
                asfDeviceId: asfDeviceId,
                asfClient: userPoolEnvironment.cognitoUserPoolASFFactory(),
                userPoolConfiguration: userPoolConfiguration
            )
            let analyticsMetadata = await userPoolEnvironment
                .cognitoUserPoolAnalyticsHandlerFactory()
                .analyticsMetadata()
            let input = ResendConfirmationCodeInput(
                analyticsMetadata: analyticsMetadata,
                clientId: userPoolConfiguration.clientId,
                // As the plugin: `[:]` when none is given (`AWSAuthResendSignUpCodeTask`), not omitted.
                clientMetadata: clientMetadata,
                secretHash: ClientSecretHelper.calculateSecretHash(
                    username: username,
                    userPoolConfiguration: userPoolConfiguration
                ),
                userContextData: CognitoIdentityProviderClientTypes.UserContextDataType(encodedData: encodedData),
                username: username
            )
            output = try await userPoolService.resendConfirmationCode(input: input)
        } catch let error as EngineAuthErrorConvertible {
            throw AuthClientError(engine: error.engineError)
        }
        guard let details = output.codeDeliveryDetails?.toEngineCodeDeliveryDetails() else {
            throw AuthClientError.unknown(
                "Unable to get Auth code delivery details",
                "This is not expected. Retry the operation."
            )
        }
        return AuthClientCodeDeliveryDetails(details)
    }

    // MARK: Auto sign-in

    /// Signs in with the auto-sign-in session (`AWSAuthAutoSignInTask.sendAutoSignInEvent`): `USER_AUTH`
    /// with the sign-up's username, client metadata and Cognito session. Keeps the auto-sign-in session
    /// whatever the outcome, so a second call reaches Cognito again (AS-3).
    ///
    /// The core calls it only after `hasAutoSignInSession` answered `true` (the plugin's first check, which
    /// keeps a pending sign-in). So the engine always supersedes first, as the plugin cancels an in-flight
    /// sign-in, and only then reads the sign-up state. If a sign-up started in between and the state is no
    /// longer signed up, the pending sign-in from before `epoch` has already ended: it could not be answered
    /// anyway, since `confirmSignIn` at this `epoch` refuses an attempt from an earlier one, so the core
    /// mirrors no challenge rather than one nothing can confirm.
    ///
    /// - Throws: `invalidState` ("Not in a signed up state…") without an auto-sign-in session; otherwise as
    ///   `signIn`, `notAuthorized` for a spent session.
    func autoSignIn(current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try requireUserPool()
        try await beginSignIn(epoch: epoch)
        return try await autoSignInAfterSuperseding(current: current, epoch: epoch)
    }

    /// The rest of `autoSignIn`, once the pending sign-in is superseded. A sign-up or confirmation may have
    /// started during that `await`, so the sign-up state is read again right before the step is sent, as the
    /// plugin's `sendAutoSignInEvent` reads its state again after `validateCurrentState`.
    ///
    /// - Throws: `invalidState` ("Not in a signed up state…") if the auto-sign-in session is gone.
    func autoSignInAfterSuperseding(current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        guard let signedUp = signUpState.autoSignInData else {
            throw SessionCore.notSignedUp()
        }
        // Built before `run`, so a cancel reaches its machine from the start and its token tap covers it.
        let operation = try resources.makeOperation(seed: current.flatMap(Self.guestSeed))
        let resources = resources
        return try await run(epoch: epoch, on: operation) {
            try await Self.autoSignInStep(signedUp, on: operation, resources: resources)
        }
    }

    /// One auto sign-in step on `operation` (seeded with a guest payload, or nothing).
    static func autoSignInStep(
        _ signedUp: SignUpEventData,
        on operation: EngineOperation,
        resources: EngineResources
    ) async throws -> SignInStepOutcome {
        try await operation.configure(resources.authConfiguration)
        await operation.send(AuthenticationEvent(eventType: .signInRequested(
            SignInEventData(
                username: signedUp.username,
                password: nil,
                clientMetadata: signedUp.clientMetadata ?? [:],
                signInMethod: .apiBased(.userAuth),
                session: signedUp.session
            ),
            true
        )))
        return try await LiveSignInSteps.awaitStep(on: operation, confirming: false)
    }

    // MARK: Running a sign-up event

    /// Sends a sign-up event to a fresh operation and waits for its result: the plugin's listener loops
    /// (`awaitingUserConfirmation` or `signedUp` is the result, `error` the failure).
    ///
    /// - Returns: the data the engine recorded (with the session Cognito answered) and the result.
    static func runSignUp(
        _ event: SignUpEvent,
        resources: EngineResources
    ) async throws -> (SignUpEventData, EngineSignUpResult) {
        let operation = try resources.makeOperation(seed: nil)
        try await operation.configure(resources.authConfiguration)
        await operation.send(event)
        return try await operation.firstState { state in
            guard case .configured(_, _, let signUpState) = state else {
                return nil
            }
            switch signUpState {
            case .awaitingUserConfirmation(let data, let result), .signedUp(let data, let result):
                return (data, result)
            case .error(let error, _):
                throw AuthClientError(signUp: error)
            case .notStarted, .initiatingSignUp, .confirmingSignUp:
                return nil
            }
        }
    }

    /// An empty dictionary is sent as omitted, as the plugin's `nil` options are (`EngineAccountRequests.swift`).
    static func omittedIfEmpty(_ values: [String: String]) -> [String: String]? {
        values.isEmpty ? nil : values
    }
}

// MARK: The sign-up state

/// The plugin's `SignUpState`, as one session's engine keeps it between calls. The plugin's
/// `initiatingSignUp` and `confirmingSignUp` are one case, `inProgress`.
enum LiveSignUpState: Sendable, Equatable {
    /// No sign-up or confirmation yet.
    case none
    /// A sign-up or confirmation is waiting for Cognito.
    case inProgress(SignUpEventData)
    /// The last sign-up returned `.confirmUser`; its data carries Cognito's session for `confirmSignUp`.
    case awaitingConfirmation(SignUpEventData)
    /// The last sign-up or confirmation completed; with a session (`.completeAutoSignIn`), `autoSignIn`
    /// can sign the user in.
    case signedUp(SignUpEventData)
    /// The last sign-up or confirmation failed; its data is the request's, with the session a confirmation
    /// sent.
    case error(SignUpEventData)

    /// The state a sign-up that returned `result` reached (`InitiateSignUp`).
    init(reached result: EngineSignUpResult, with data: SignUpEventData) {
        switch result.nextStep {
        case .confirmUser:
            self = .awaitingConfirmation(data)
        case .completeAutoSignIn, .done:
            self = .signedUp(data)
        }
    }

    /// The session `confirmSignUp(username)` sends: the plugin's, from `awaitingUserConfirmation` or `error`
    /// when the username matches, else none.
    func confirmationSession(for username: String) -> String? {
        switch self {
        case .awaitingConfirmation(let data), .error(let data):
            return data.username == username ? data.session : nil
        case .none, .inProgress, .signedUp:
            return nil
        }
    }

    /// What `autoSignIn` signs in with: a `signedUp` state that carries Cognito's session. The plugin also
    /// accepts a `signedUp` state without one (a `.done` sign-up) and sends `USER_AUTH` with no session. What
    /// Cognito answers that is not checked (likely a `SELECT_CHALLENGE` sign-in, not an auto sign-in); the
    /// client refuses it with the plugin's "Not in a signed up state…".
    var autoSignInData: SignUpEventData? {
        guard case .signedUp(let data) = self, data.session != nil else {
            return nil
        }
        return data
    }
}

// MARK: Engine -> client

extension AuthClientSignUpResult {

    init(_ result: EngineSignUpResult) {
        self.init(AuthClientSignUpStep(result.nextStep), userId: result.userID)
    }
}

extension AuthClientSignUpStep {

    /// Case for case with `EngineSignUpStep`, as the plugin maps it to `AuthSignUpStep`.
    init(_ step: EngineSignUpStep) {
        switch step {
        case .confirmUser(let details, let info, let userId):
            self = .confirmUser(details.map(AuthClientCodeDeliveryDetails.init), info, userId)
        case .completeAutoSignIn(let session):
            self = .completeAutoSignIn(session)
        case .done:
            self = .done
        }
    }
}

extension AuthClientError {

    /// A sign-up machine's failure, as the plugin's `SignUpError.authError` maps it. The engine only ever
    /// reports `.service` (its actions wrap every failure), so the two cases its own mapping leaves to a
    /// `fatalError` are mapped here instead of trapping.
    init(signUp error: SignUpError) {
        switch error {
        case .invalidState(let message):
            self = .invalidState(message, "Call signUp, then confirmSignUp.")
        case .invalidConfirmationCode(let message):
            self = .validation(field: "code", message, "Make sure that a valid code is passed for confirmSignUp")
        case .invalidUsername, .invalidPassword, .service:
            self.init(engine: error.engineError)
        }
    }
}
