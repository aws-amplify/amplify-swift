//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AuthenticationServices
import Foundation

/// One passkey registration or assertion through `ASAuthorizationController`, for the raw driver.
///
/// The same requests the engine's `PlatformWebAuthnCredentials` makes, with the same JSON encodings
/// (`AWSWebAuthCredentialsModels.swift`), so WA-0 exercises exactly what the client will send.
@MainActor
final class PasskeyCeremony: NSObject {
    private let anchor: ASPresentationAnchor
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    /// Kept so `cancel()` can stop a ceremony whose sheet never appeared or is still open.
    private var controller: ASAuthorizationController?

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    /// Registers a platform passkey for `options` (Cognito's `CredentialCreationOptions` JSON) and
    /// returns the `CompleteWebAuthnRegistration` credential JSON.
    func register(options: [String: Any]) async throws -> [String: Any] {
        guard let challenge = (options["challenge"] as? String).flatMap(Data.init(base64URL:)),
              let relyingParty = (options["rp"] as? [String: Any])?["id"] as? String,
              let user = options["user"] as? [String: Any],
              let userName = user["name"] as? String,
              let userID = (user["id"] as? String).flatMap(Data.init(base64URL:)) else {
            throw HarnessAppError("Malformed credential creation options: \(options.keys.sorted())")
        }
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingParty)
        let request = provider.createCredentialRegistrationRequest(challenge: challenge, name: userName, userID: userID)
        let excluded = (options["excludeCredentials"] as? [[String: Any]]) ?? []
        request.excludedCredentials = excluded.compactMap { credential in
            (credential["id"] as? String).flatMap(Data.init(base64URL:)).map {
                ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0)
            }
        }
        let authorization = try await perform(request)
        guard let registration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration,
              let attestation = registration.rawAttestationObject else {
            throw HarnessAppError("The passkey sheet returned \(type(of: authorization.credential)), not a registration")
        }
        let id = registration.credentialID.base64URL
        return [
            "id": id,
            "rawId": id,
            "type": "public-key",
            "authenticatorAttachment": "platform",
            "response": [
                "attestationObject": attestation.base64URL,
                "clientDataJSON": registration.rawClientDataJSON.base64URL,
                "transports": ["internal"]
            ]
        ]
    }

    /// Asserts a platform passkey for `options` (the `CREDENTIAL_REQUEST_OPTIONS` challenge parameter)
    /// and returns the `CREDENTIAL` challenge response JSON.
    func assert(options: [String: Any]) async throws -> [String: Any] {
        guard let challenge = (options["challenge"] as? String).flatMap(Data.init(base64URL:)),
              let relyingParty = options["rpId"] as? String else {
            throw HarnessAppError("Malformed credential request options: \(options.keys.sorted())")
        }
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingParty)
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        let authorization = try await perform(request)
        guard let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
            throw HarnessAppError("The passkey sheet returned \(type(of: authorization.credential)), not an assertion")
        }
        let id = assertion.credentialID.base64URL
        return [
            "id": id,
            "rawId": id,
            "type": "public-key",
            "authenticatorAttachment": "platform",
            "response": [
                "authenticatorData": assertion.rawAuthenticatorData.base64URL,
                "clientDataJSON": assertion.rawClientDataJSON.base64URL,
                "signature": assertion.signature.base64URL,
                "userHandle": assertion.userID.base64URL
            ]
        ]
    }

    private func perform(_ request: ASAuthorizationRequest) async throws -> ASAuthorization {
        guard continuation == nil else {
            throw HarnessAppError("A passkey ceremony is already in progress")
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    /// Cancels the ceremony in flight, if any. The controller answers `.canceled`; should it not (no sheet
    /// was ever shown), the pending call is failed here so the app is never left busy.
    func cancel() {
        controller?.cancel()
        finish(.failure(ASAuthorizationError(.canceled)))
    }

    private func finish(_ result: Result<ASAuthorization, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        controller = nil
    }
}

extension PasskeyCeremony: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        MainActor.assumeIsolated { finish(.success(authorization)) }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        MainActor.assumeIsolated { finish(.failure(error)) }
    }
}

extension PasskeyCeremony: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated { anchor }
    }
}

extension Data {
    init?(base64URL string: String) {
        var base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        self.init(base64Encoded: base64)
    }

    var base64URL: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
