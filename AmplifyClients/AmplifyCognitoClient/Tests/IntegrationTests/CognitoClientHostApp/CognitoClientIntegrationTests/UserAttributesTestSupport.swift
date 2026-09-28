//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import XCTest

/// What the password-reset, user-attribute and stress suites share: a fresh user signed in
/// through the client under test, and failure messages that name an error's case only.
extension ClientIntegrationTestCase {

    /// A fresh user on `pool` (`makeFreshUser`, deleted in `tearDown`), signed in with its password by a
    /// new client on that pool, the plugin's `registerAndSignInUser`. Hold the client in a local.
    func makeSignedInFreshUser(
        _ tag: String,
        on pool: SandboxPool = .standard
    ) async throws -> (client: AmplifyCognitoClient, user: FreshUser) {
        let user = try await makeFreshUser(on: pool)
        let client = try makeClient(tag, pool: pool)
        let result = try await client.signIn(username: user.username, password: XCTUnwrap(user.password))
        guard result.nextStep == .done else {
            throw HarnessError.malformedFixture("a fresh user's sign-in did not complete")
        }
        return (client, user)
    }
}

/// An error's case, for a failure message: never its description, which can carry a request ID or
/// what Cognito echoed back.
enum ClientErrorShape {

    static func of(_ error: Error) -> String {
        guard let error = error as? AuthClientError else {
            return String(describing: type(of: error))
        }
        switch error {
        case .service(let code, _, _, _):
            return "service(\(code.map { "\($0)" } ?? "nil"))"
        case .validation(let field, _, _, _):
            return "validation(\(field))"
        case .configuration: return "configuration"
        case .storageUnavailable: return "storageUnavailable"
        case .sessionExpired: return "sessionExpired"
        case .notSignedIn: return "notSignedIn"
        case .invalidSessionID: return "invalidSessionID"
        case .challengeExpired: return "challengeExpired"
        case .browserBusy: return "browserBusy"
        case .sessionConfigurationMismatch: return "sessionConfigurationMismatch"
        case .notAuthorized: return "notAuthorized"
        case .invalidState: return "invalidState"
        case .userCancelled: return "userCancelled"
        case .webAuthnCeremonyFailed: return "webAuthnCeremonyFailed"
        case .unexpectedIdentity: return "unexpectedIdentity"
        case .unknown: return "unknown"
        }
    }
}
