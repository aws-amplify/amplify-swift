//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) import AmplifyFoundation

final class AccessTokenProviderTests: XCTestCase {

    /// Vends its token, or fails as the protocol's contract says: with a `CredentialsError`.
    private struct FakeTokenProvider: AccessTokenProvider {
        let token: String?

        func accessToken() async throws -> String {
            guard let token else {
                throw CredentialsError.sessionExpired("expired", "sign in again")
            }
            return token
        }
    }

    /// A consumer needs only AmplifyFoundation to take a token provider.
    ///
    /// - Given: a provider that vends a token, and one whose session has expired, each held as
    ///   `any AccessTokenProvider`
    /// - When: a consumer asks the first for a token from another task, and the second directly
    /// - Then:
    ///    - the first vends its token
    ///    - the second fails with a `CredentialsError`, whose `disposition` keeps buffered work
    func testAConsumerTakesAnyTokenProvider() async throws {
        let signedIn: any AccessTokenProvider = FakeTokenProvider(token: "token")
        let expired: any AccessTokenProvider = FakeTokenProvider(token: nil)

        let token = try await Task { try await signedIn.accessToken() }.value
        XCTAssertEqual(token, "token")

        do {
            _ = try await expired.accessToken()
            XCTFail("expected a CredentialsError")
        } catch let error as CredentialsError {
            XCTAssertEqual(error.disposition, .retryAfterReauthentication)
        }
    }
}
