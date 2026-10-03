//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// The G1(c) client-compile probe. A client file that imports
// only AWSCognitoAuthPlugin and uses the plugin's public types the engine touches: it constructs them,
// switches over them exhaustively, reads their members and extends them. It must type-check both with and
// without `-enable-upcoming-feature MemberImportVisibility` (SE-0444), so a relocation or re-export that
// only works without that feature fails here. Run it with scripts/m2/run_miv_probe.sh. Never linked.

import AWSCognitoAuthPlugin
import Foundation

// MARK: AuthFlowType (public, persisted)

func probeAuthFlowType(_ flow: AuthFlowType) -> String {
    switch flow {
    case .userSRP: return "srp"
    case .custom: return "custom" // deprecated, still public
    case .customWithSRP: return "customWithSRP"
    case .customWithoutSRP: return "customWithoutSRP"
    case .userPassword: return "password"
    case .userAuth(let factor): return "userAuth \(String(describing: factor))"
    }
}

func probeAuthFlowTypeValues() -> Bool {
    let flows: [AuthFlowType] = [.userSRP, .customWithSRP, .customWithoutSRP, .userPassword, .userAuth, .userAuth(preferredFirstFactor: nil)]
    let options = AWSAuthSignInOptions(metadata: ["key": "value"], authFlowType: .customWithoutSRP)
    return flows.contains(AuthFlowType.userAuth) && options.authFlowType == .customWithoutSRP && options.metadata?.isEmpty == false
}

// MARK: Tokens and credentials (public, persisted)

@available(*, deprecated, message: "Uses the deprecated token initializers on purpose")
func probeTokens() -> String {
    let tokens = AWSCognitoUserPoolTokens(idToken: "id", accessToken: "access", refreshToken: "refresh", expiration: Date())
    let legacy = AWSCognitoUserPoolTokens(idToken: "id", accessToken: "access", refreshToken: "refresh", expiresIn: 3_600)
    _ = tokens == legacy
    _ = tokens.expiration
    return tokens.idToken + tokens.accessToken + tokens.refreshToken + tokens.debugDescription
}

func probeTokensCodable(_ tokens: AWSCognitoUserPoolTokens) throws -> AWSCognitoUserPoolTokens {
    try JSONDecoder().decode(AWSCognitoUserPoolTokens.self, from: JSONEncoder().encode(tokens))
}

func probeCredentials(_ credentials: AuthAWSCognitoCredentials) throws -> String {
    let copy = try JSONDecoder().decode(AuthAWSCognitoCredentials.self, from: JSONEncoder().encode(credentials))
    _ = copy == credentials
    return credentials.accessKeyId + credentials.secretAccessKey + credentials.sessionToken
        + "\(credentials.expiration)" + credentials.debugDescription
}

// MARK: Session

func probeSession(_ session: AWSAuthCognitoSession) -> Bool {
    _ = session.getAWSCredentials()
    _ = session.getCognitoTokens()
    _ = session.getIdentityId()
    _ = session.getUserSub()
    _ = session.userSubResult
    _ = session.identityIdResult
    _ = session.awsCredentialsResult
    _ = session.userPoolTokensResult
    _ = session.debugDescription
    return session.isSignedIn && session == session
}

// MARK: Sign-out results and their errors

func probeSignOut(_ result: AWSCognitoSignOutResult) -> String {
    switch result {
    case .complete:
        return "complete \(result.signedOutLocally)"
    case .partial(let revoke, let global, let hostedUI):
        return [
            revoke.map { "\($0.refreshToken) \($0.error)" },
            global.map { "\($0.accessToken) \($0.error)" },
            hostedUI.map { "\($0.error)" }
        ].compactMap { $0 }.joined()
    case .failed(let error):
        return "\(error)"
    }
}

// MARK: AWSCognitoAuthError

func probeServiceError(_ error: Error) -> String {
    guard let code = error as? AWSCognitoAuthError else { return "other" }
    switch code {
    case .userNotFound, .userNotConfirmed, .usernameExists, .aliasExists, .codeDelivery, .codeMismatch,
         .codeExpired, .invalidParameter, .invalidPassword, .limitExceeded, .mfaMethodNotFound,
         .softwareTokenMFANotEnabled, .passwordResetRequired, .resourceNotFound, .failedAttemptsLimitExceeded,
         .requestLimitExceeded, .lambda, .deviceNotTracked, .errorLoadingUI, .userCancelled,
         .invalidAccountTypeException, .network, .smsRole, .emailRole, .externalServiceException,
         .limitExceededException, .resourceConflictException, .webAuthnChallengeNotFound,
         .webAuthnClientMismatch, .webAuthnNotSupported, .webAuthnNotEnabled, .webAuthnOriginNotAllowed,
         .webAuthnRelyingPartyMismatch, .webAuthnConfigurationMissing:
        return code.errorDescription ?? ""
    }
}

// MARK: Users, devices, federation

func probeUser(_ user: AWSAuthUser) -> String {
    user.username + user.userId
}

func probeDevice() -> String {
    let device = AWSAuthDevice(id: "id", name: "name", attributes: ["a": "b"], createdDate: nil, lastAuthenticatedDate: nil, lastModifiedDate: nil)
    return device.id + device.name + "\(String(describing: device.attributes))"
}

func probeFederation(_ result: FederateToIdentityPoolResult) -> String {
    // `credentials` is an AWSPluginsCore protocol: reading its members needs `import AWSPluginsCore` under
    // MemberImportVisibility, before and after the engine move, so the probe only touches the plugin-declared member.
    result.identityId + "\(type(of: result.credentials))"
}

// MARK: Hosted UI options

func probeWebUIOptions() -> Int {
    let options = AWSAuthWebUISignInOptions(
        idpIdentifier: "idp",
        preferPrivateSession: true,
        nonce: "nonce",
        language: "en",
        loginHint: "hint",
        prompt: [.login, .consent, .selectAccount, .none],
        resource: "resource"
    )
    for prompt in options.prompt ?? [] {
        switch prompt {
        case .none, .login, .selectAccount, .consent: _ = prompt.rawValue
        }
    }
    return (options.prompt?.count ?? 0) + (options.preferPrivateSession ? 1 : 0)
}

// MARK: Client extensions on the plugin's types

extension AuthFlowType {
    var probeIsCustom: Bool {
        switch self {
        case .customWithSRP, .customWithoutSRP: return true
        default: return false
        }
    }
}

extension AWSCognitoUserPoolTokens {
    var probeTokenLength: Int { accessToken.count }
}

extension AuthAWSCognitoCredentials {
    var probeHasSession: Bool { !sessionToken.isEmpty }
}

extension AWSCognitoAuthError {
    var probeIsNetwork: Bool { self == .network }
}

extension AWSCognitoSignOutResult {
    var probeIsPartial: Bool {
        if case .partial = self { return true }
        return false
    }
}
