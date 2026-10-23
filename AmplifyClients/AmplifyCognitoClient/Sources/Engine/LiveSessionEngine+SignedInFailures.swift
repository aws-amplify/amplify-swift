//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// How a signed-in operation of the live engine reports what it throws, per the seam's error contract.
/// Shared: WebAuthn credential list and delete use it today, and any other signed-in
/// operation that calls the engine directly can wrap its body in `mappingSignedInFailures` the same way.
///
/// **The caller cancelling its own task is `CancellationError`, never `.service` or `.userCancelled`**.
/// Three shapes reach here for it:
/// - a bare `CancellationError`;
/// - the engine's `.service("An unknown error type was thrown by the service. …")` with a `CancellationError`
///   underneath, which is how the engine reports a cancelled Cognito call (the plugin's behaviour, kept);
/// - any other failure while the calling task is cancelled, whatever the SDK threw for it (for example
///   `URLError.cancelled` from a cancelled load).
///
/// Everything else the engine throws is an `EngineAuthError`, mapped by `AuthClientError(engine:)`, or a
/// `WebAuthnCredentialOperations.Failure`, mapped by `AuthClientError(engine:cause:)` with the error it was made
/// from, so a Cognito internal error is `.service` as elsewhere. An error of any other type passes through, for the
/// core's `operationFailure`.
extension LiveSessionEngine {

    /// Runs `body` and throws what `signedInFailure(_:cancelled:)` makes of its error.
    static func mappingSignedInFailures<T>(_ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch {
            throw signedInFailure(error, cancelled: Task.isCancelled)
        }
    }

    /// What a signed-in operation throws for `error`; `cancelled` is whether the calling task was cancelled.
    static func signedInFailure(_ error: Error, cancelled: Bool) -> Error {
        if cancelled || error is CancellationError {
            return CancellationError()
        }
        let engineError: EngineAuthError
        let cause: Error?
        if let failure = error as? WebAuthnCredentialOperations.Failure {
            (engineError, cause) = (failure.engineError, failure.cause)
        } else if let error = error as? EngineAuthError {
            (engineError, cause) = (error, nil)
        } else {
            return error
        }
        if case .service(_, _, let underlying) = engineError, underlying is CancellationError {
            return CancellationError()
        }
        return AuthClientError(engine: engineError, cause: cause)
    }
}
