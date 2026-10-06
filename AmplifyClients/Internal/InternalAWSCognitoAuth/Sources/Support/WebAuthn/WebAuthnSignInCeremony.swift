//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// How a WebAuthn sign-in's assertion runs.
///
/// Every `AuthEnvironment` has one, **empty by default, which is the plugin's path, unchanged**:
/// `AssertWebAuthnCredentials` asserts with its own asserter, over the anchor the sign-in's event data
/// carries. `AmplifyCognitoClient` fills it before each sign-in step with a `Ceremony`, and the assertion
/// then runs as that ceremony says (`Ceremony.assert(_:)`):
/// - **no anchor** (a sign-in without a window reached a WebAuthn step): refused with
///   `EngineAuthError.validation("presentationAnchor", …)` before the runner, so nothing is presented;
/// - otherwise **inside the ceremony's runner** (the client's process-wide sheet lease). The body unboxes
///   the anchor on the main actor (a window that has gone is the same `.validation`, and nothing is
///   presented), makes the asserter there, and asserts. It converts its own errors to `WebAuthnError`
///   before they leave it, so an error from the runner that is not a `WebAuthnError` is the runner's own
///   (the lease's refusal, or its `CancellationError`), and reaches the sign-in as the underlying error of
///   `WebAuthnError.unknown`, unchanged.
///
/// Read once, when the assertion starts; the caller sets it before sending the step's event.
package final class WebAuthnSignInCeremonySlot: @unchecked Sendable {

    /// One sign-in step's ceremony: the window and the runner.
    package struct Ceremony: Sendable {
        /// The window, boxed on the main actor by the caller; `nil` when the step was given none.
        package let anchor: EnginePresentationAnchorBox?
        /// Runs the assertion body, once, under whatever the caller holds around a ceremony.
        package let run: WebAuthnCredentialOperations.CeremonyRunner
        #if os(iOS) || os(macOS) || os(visionOS)
        /// Makes the asserter from the unboxed window, on the main actor; `nil` makes
        /// `PlatformWebAuthnCredentials`. A test passes one that presents nothing. It must return a
        /// `CredentialAsserterProtocol`.
        package let makeAsserter: (@MainActor @Sendable (EnginePresentationAnchor) -> any WebAuthnCredentialsProtocol)?

        package init(
            anchor: EnginePresentationAnchorBox?,
            run: @escaping WebAuthnCredentialOperations.CeremonyRunner,
            makeAsserter: (@MainActor @Sendable (EnginePresentationAnchor) -> any WebAuthnCredentialsProtocol)? = nil
        ) {
            self.anchor = anchor
            self.run = run
            self.makeAsserter = makeAsserter
        }
        #else
        package init(anchor: EnginePresentationAnchorBox?, run: @escaping WebAuthnCredentialOperations.CeremonyRunner) {
            self.anchor = anchor
            self.run = run
        }
        #endif
    }

    private let lock = NSLock()
    private var stored: Ceremony?

    package init() {}

    /// The ceremony the next assertion runs, or `nil` for the plugin's path.
    package var ceremony: Ceremony? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

package extension WebAuthnCredentialOperations {

    /// A WebAuthn step reached without a presentation anchor.
    static let presentationAnchorMissingDescription =
        "A WebAuthn sign-in step needs a presentation anchor, and none was given, so the passkey sheet was not presented."
    static let presentationAnchorMissingRecovery =
        "Pass the window the passkey sheet attaches to (a presentationAnchor), such as the key window of the active scene."
}

#if os(iOS) || os(macOS) || os(visionOS)
extension WebAuthnSignInCeremonySlot.Ceremony {

    /// The assertion, run as this ceremony says (see `WebAuthnSignInCeremonySlot`).
    ///
    /// - Returns: the assertion payload, as `AssertWebAuthnCredentials` sends it to Cognito.
    /// - Throws: `EngineAuthError.validation("presentationAnchor", …)` with no anchor, before the runner;
    ///   a `WebAuthnError` from the body; the runner's own error unchanged.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    package func assert(_ options: CredentialAssertionOptions, logger: any EngineScopedLogger) async throws -> String {
        guard let anchor else {
            throw EngineAuthError.validation(
                WebAuthnCredentialOperations.presentationAnchorField,
                WebAuthnCredentialOperations.presentationAnchorMissingDescription,
                WebAuthnCredentialOperations.presentationAnchorMissingRecovery
            )
        }
        let makeAsserter = makeAsserter
        let data = try await run {
            do {
                let asserter = try await MainActor.run {
                    try Self.asserter(from: anchor, makeAsserter, logger: logger)
                }
                let payload = try await asserter.assert(with: options)
                return try Data(payload.stringify().utf8)
            } catch {
                throw AssertWebAuthnCredentials.webAuthnError(from: error)
            }
        }
        // `data` is the runner's return of the body above, `Data(payload.stringify().utf8)`: always valid UTF-8,
        // so decoding it replaces nothing, and a failable conversion would add a failure that cannot happen.
        // The same conversion as `CredentialAssertionPayload.stringify()`.
        // swiftlint:disable:next optional_data_string_conversion
        return String(decoding: data, as: UTF8.self)
    }

    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    @MainActor
    private static func asserter(
        from box: EnginePresentationAnchorBox,
        _ makeAsserter: (@MainActor @Sendable (EnginePresentationAnchor) -> any WebAuthnCredentialsProtocol)?,
        logger: any EngineScopedLogger
    ) throws -> CredentialAsserterProtocol {
        guard let window = box.anchor else {
            throw EngineAuthError.validation(
                WebAuthnCredentialOperations.presentationAnchorField,
                WebAuthnCredentialOperations.presentationAnchorGoneDescription,
                WebAuthnCredentialOperations.presentationAnchorGoneRecovery
            )
        }
        guard let makeAsserter else {
            return PlatformWebAuthnCredentials(presentationAnchor: window, logger: logger)
        }
        guard let asserter = makeAsserter(window) as? CredentialAsserterProtocol else {
            throw WebAuthnError.unknown(message: "The ceremony's asserter cannot assert WebAuthn credentials")
        }
        return asserter
    }
}
#endif
