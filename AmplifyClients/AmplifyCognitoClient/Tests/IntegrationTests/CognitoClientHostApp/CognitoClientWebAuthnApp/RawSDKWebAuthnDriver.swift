//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AuthenticationServices
import AWSCognitoIdentityProvider
import Foundation
import Smithy
import SmithyJSON

/// WA-0: the WebAuthn flow over the raw Cognito API, with no Amplify and no client in the path.
///
/// It proves the sandbox (the WebAuthn pool's `WEB_AUTHN` factor and relying party), the relying
/// party's association with this app ID, and the simulator's Face ID enrolment and matching, before
/// the client has a WebAuthn API. The calls are the ones the engine makes (the plugin's
/// `AssociateWebAuthnCredentialTask`, `ListWebAuthnCredentialsTask`, `DeleteWebAuthnCredentialTask`
/// and the `WebAuthnSignInState` actions), so WA-1 differs from WA-0 only in who makes them.
@MainActor
final class RawSDKWebAuthnDriver: WebAuthnHarnessDriver {
    let name = "raw Cognito API"

    private let client: CognitoIdentityProviderClient
    private let clientId: String
    private var accessToken: String?
    private var refreshToken: String?
    private var ceremony: PasskeyCeremony?

    init(configuration: AuthClientConfiguration) throws {
        guard let userPool = configuration.userPool else {
            throw HarnessAppError("The WebAuthn pool outputs have no user pool")
        }
        self.clientId = userPool.appClientId
        self.client = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: userPool.region)
        )
    }

    func signUpAndSignIn(username: String, password: String, email: String, signedUp: @MainActor () -> Void) async throws {
        _ = try await client.signUp(input: SignUpInput(
            clientId: clientId,
            password: password,
            userAttributes: [.init(name: "email", value: email)],
            username: username
        ))
        signedUp()
        let result = try await client.initiateAuth(input: InitiateAuthInput(
            authFlow: .userPasswordAuth,
            authParameters: ["USERNAME": username, "PASSWORD": password],
            clientId: clientId
        ))
        try keep(result.authenticationResult, after: "USER_PASSWORD_AUTH", challenge: result.challengeName?.rawValue)
    }

    func signInWithWebAuthn(username: String, presentationAnchor: ASPresentationAnchor) async throws {
        let start = try await client.initiateAuth(input: InitiateAuthInput(
            authFlow: .userAuth,
            authParameters: ["USERNAME": username, "PREFERRED_CHALLENGE": "WEB_AUTHN"],
            clientId: clientId
        ))
        guard start.challengeName == .webAuthn,
              let options = start.challengeParameters?["CREDENTIAL_REQUEST_OPTIONS"] else {
            throw HarnessAppError("USER_AUTH with WEB_AUTHN preferred answered \(start.challengeName?.rawValue ?? "no challenge")")
        }
        let credential = try await withCeremony(presentationAnchor) { try await $0.assert(options: jsonObject(options)) }
        let result = try await client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .webAuthn,
            challengeResponses: ["USERNAME": username, "CREDENTIAL": jsonString(credential)],
            clientId: clientId,
            session: start.session
        ))
        try keep(result.authenticationResult, after: "WEB_AUTHN", challenge: result.challengeName?.rawValue)
    }

    func signOut() async throws {
        if let refreshToken {
            _ = try await client.revokeToken(input: RevokeTokenInput(clientId: clientId, token: refreshToken))
        }
        accessToken = nil
        refreshToken = nil
    }

    func associateWebAuthnCredential(presentationAnchor: ASPresentationAnchor) async throws {
        let token = try signedIn()
        let start = try await client.startWebAuthnRegistration(input: StartWebAuthnRegistrationInput(accessToken: token))
        guard let document = start.credentialCreationOptions,
              let options = jsonObject(document) as? [String: Any] else {
            throw HarnessAppError("StartWebAuthnRegistration returned no credential creation options")
        }
        let credential = try await withCeremony(presentationAnchor) { try await $0.register(options: options) }
        _ = try await client.completeWebAuthnRegistration(input: CompleteWebAuthnRegistrationInput(
            accessToken: token,
            credential: Document.make(from: credential as Any)
        ))
    }

    func listWebAuthnCredentials() async throws -> [String] {
        let result = try await client.listWebAuthnCredentials(input: ListWebAuthnCredentialsInput(
            accessToken: signedIn(),
            maxResults: 20
        ))
        return (result.credentials ?? []).compactMap(\.credentialId)
    }

    func deleteWebAuthnCredential(credentialId: String) async throws {
        _ = try await client.deleteWebAuthnCredential(input: DeleteWebAuthnCredentialInput(
            accessToken: signedIn(),
            credentialId: credentialId
        ))
    }

    func deleteUser(username: String, password: String) async throws {
        if accessToken == nil {
            let result = try await client.initiateAuth(input: InitiateAuthInput(
                authFlow: .userPasswordAuth,
                authParameters: ["USERNAME": username, "PASSWORD": password],
                clientId: clientId
            ))
            try keep(result.authenticationResult, after: "USER_PASSWORD_AUTH", challenge: result.challengeName?.rawValue)
        }
        _ = try await client.deleteUser(input: DeleteUserInput(accessToken: signedIn()))
        accessToken = nil
        refreshToken = nil
    }

    func cancelCeremony() {
        ceremony?.cancel()
    }

    private func withCeremony(
        _ anchor: ASPresentationAnchor,
        _ body: (PasskeyCeremony) async throws -> [String: Any]
    ) async throws -> [String: Any] {
        let ceremony = PasskeyCeremony(anchor: anchor)
        self.ceremony = ceremony
        defer { self.ceremony = nil }
        return try await body(ceremony)
    }

    private func signedIn() throws -> String {
        guard let accessToken else {
            throw HarnessAppError("No user is signed in")
        }
        return accessToken
    }

    private func keep(
        _ result: CognitoIdentityProviderClientTypes.AuthenticationResultType?,
        after flow: String,
        challenge: String?
    ) throws {
        guard let access = result?.accessToken, let refresh = result?.refreshToken else {
            throw HarnessAppError("\(flow) returned no tokens (challenge \(challenge ?? "none"))")
        }
        accessToken = access
        refreshToken = refresh
    }

    private func jsonObject(_ string: String) throws -> [String: Any] {
        guard let object = try JSONSerialization.jsonObject(with: Data(string.utf8)) as? [String: Any] else {
            throw HarnessAppError("The credential request options are not a JSON object")
        }
        return object
    }

    private func jsonString(_ object: [String: Any]) throws -> String {
        try String(decoding: JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]), as: UTF8.self)
    }

    /// A Smithy document as the JSON object it was decoded from.
    private func jsonObject(_ document: SmithyDocument) -> Any {
        if let map = try? document.asStringMap() {
            return map.mapValues { jsonObject($0) }
        }
        if let list = try? document.asList() {
            return list.map { jsonObject($0) }
        }
        if let string = try? document.asString() {
            return string
        }
        if let boolean = try? document.asBoolean() {
            return boolean
        }
        if let number = try? document.asDouble() {
            return number
        }
        return NSNull()
    }
}
