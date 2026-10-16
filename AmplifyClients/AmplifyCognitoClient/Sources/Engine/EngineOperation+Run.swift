//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// Running one operation's machines: configure, send, await a state, read the
/// slot back.
extension EngineOperation {

    /// How long configuring an operation may take. It is in-memory work only (the slot, the inert legacy
    /// keychain), so the bound only turns an engine bug into an error instead of a hang (the
    /// plugin's unbounded `didStateMachineConfigured` is not inherited).
    static let configureBoundNanoseconds: UInt64 = 5_000_000_000

    /// Sends `.configureAuth` and waits, within `boundNanoseconds`, for the machine to read `.configured`.
    ///
    /// Configuring reads the operation's slot (through the credential store machine, whose legacy migration
    /// sees the inert legacy keychain) and nothing else: no Cognito call, and no keychain call (the
    /// engine's contract).
    ///
    /// - Returns: the authentication and authorization states the machine was configured into.
    /// - Throws: `AuthClientError.unknown` if it does not configure in time; `CancellationError` if the task
    ///   is cancelled meanwhile.
    @discardableResult
    func configure(
        _ configuration: AuthConfiguration,
        boundNanoseconds: UInt64 = configureBoundNanoseconds
    ) async throws -> (AuthenticationState, AuthorizationState) {
        // `InternalAWSCognitoAuth.AuthEvent`: the client has a public `AuthEvent` of its own.
        await authMachine.send(InternalAWSCognitoAuth.AuthEvent(eventType: .configureAuth(configuration)))
        let operation = self
        return try await Self.bounded(boundNanoseconds, "Configuring the session's Cognito engine") {
            try await operation.firstState { state in
                if case .configured(let authentication, let authorization, _) = state {
                    return (authentication, authorization)
                }
                return nil
            }
        }
    }

    /// Sends an event to the operation's auth machine. The machine resolves it before this returns, so a
    /// `firstState` that starts afterwards never sees the state from before the event.
    func send(_ event: StateMachineEvent) async {
        await authMachine.send(event)
    }

    /// The first state, from the current one on, for which `decide` returns a value. `decide` throws to end
    /// the wait with a failure.
    ///
    /// Unbounded, as the plugin's tasks are: every wait after configure is for a Cognito call, which the SDK
    /// bounds with its own timeouts and retries.
    ///
    /// - Throws: whatever `decide` throws; `CancellationError` when the task is cancelled, which ends the
    ///   machine's stream.
    func firstState<Result: Sendable>(_ decide: (AuthState) throws -> Result?) async throws -> Result {
        let states = await authMachine.listen()
        for await state in states {
            if let result = try decide(state) {
                return result
            }
        }
        try Task.checkCancellation()
        throw AuthClientError.unknown(
            "The session's Cognito engine stopped before the operation finished.",
            "This is not expected. Retry the operation."
        )
    }

    /// Subscribes to the machine, sends `event`, then waits as `firstState` does: every state from the one
    /// before the event on is seen, so `decide` can follow a flow through its intermediate states.
    func firstState<Result: Sendable>(
        after event: StateMachineEvent,
        _ decide: (AuthState) throws -> Result?
    ) async throws -> Result {
        let states = await authMachine.listen()
        await authMachine.send(event)
        for await state in states {
            if let result = try decide(state) {
                return result
            }
        }
        try Task.checkCancellation()
        throw AuthClientError.unknown(
            "The session's Cognito engine stopped before the operation finished.",
            "This is not expected. Retry the operation."
        )
    }

    /// The payload the operation established: the slot's written credentials, which must be the terminal
    /// state's.
    ///
    /// A terminal state whose credentials disagree with the slot, or a slot the engine never wrote, is an
    /// engine contract violation: it asserts in debug builds and throws `.unknown` in release builds.
    func payload(establishing credentials: AmplifyCredentials) throws -> Data {
        guard case .written(let written) = slot.current, written == credentials else {
            assertionFailure("The engine established credentials it did not store in the operation's slot")
            throw AuthClientError.unknown(
                "The session's Cognito engine established credentials it did not store.",
                "This is not expected. Sign in again."
            )
        }
        return try CredentialSlot.encode(written)
    }

    /// Runs `body`, or throws `.unknown` once `nanoseconds` have passed. Cancelling the caller cancels both.
    static func bounded<Result: Sendable>(
        _ nanoseconds: UInt64,
        _ what: String,
        _ body: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        return try await withThrowingTaskGroup(of: BoundedRace<Result>.self) { group in
            group.addTask { try await .finished(body()) }
            group.addTask {
                try await Task.sleep(nanoseconds: nanoseconds)
                return .timedOut
            }
            defer { group.cancelAll() }
            switch try await group.next() {
            case .finished(let result):
                return result
            case .timedOut, nil:
                throw AuthClientError.unknown(
                    "\(what) did not finish in time.",
                    "This is not expected. Retry the operation."
                )
            }
        }
    }
}

/// Which finished first in `EngineOperation.bounded`.
private enum BoundedRace<Result: Sendable>: Sendable {
    case finished(Result)
    case timedOut
}
