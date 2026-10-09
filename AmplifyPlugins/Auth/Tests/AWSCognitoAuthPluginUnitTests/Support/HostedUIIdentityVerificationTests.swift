//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The engine side of the hosted UI's identity check: `HostedUIIdentityPolicy`, `HostedUIIdentityVerifier`
/// and the `HostedUIError.unexpectedIdentity` case.
class HostedUIIdentityVerificationTests: XCTestCase {

    private let clientId = "hostedUIClient"
    private let poolId = "us-east-1_pool"
    private let region = "us-east-1"
    private let nonce = "flowNonce"

    // MARK: - The policy

    /// Test that `.none` verifies nothing
    ///
    /// - Given: The `.none` policy, the plugin's only policy
    /// - When:
    ///    - Tokens that are not JWTs at all are verified
    /// - Then:
    ///    - Nothing is thrown, because nothing is read
    ///
    func testNonePolicyReadsNothing() throws {
        XCTAssertTrue(HostedUIIdentityPolicy.none.isNone)
        XCTAssertNoThrow(try verify(idToken: "not a jwt", accessToken: "", policy: .none))
    }

    /// Test that any setting makes a policy active
    ///
    /// - Given: Policies with one setting each
    /// - When:
    ///    - `isNone` is read
    /// - Then:
    ///    - Only the policy with no setting is `.none`
    ///
    func testAnySettingMakesThePolicyActive() {
        XCTAssertTrue(HostedUIIdentityPolicy(verifiesTokenClaims: false).isNone)
        XCTAssertFalse(HostedUIIdentityPolicy(verifiesTokenClaims: true).isNone)
        XCTAssertFalse(HostedUIIdentityPolicy(verifiesTokenClaims: false, expectedIdentity: "user").isNone)
        XCTAssertFalse(HostedUIIdentityPolicy(verifiesTokenClaims: false, excludedSubjects: ["sub"]).isNone)
    }

    // MARK: - Token claims

    /// Test that a response belonging to this flow passes
    ///
    /// - Given: An id token for this client, pool and nonce, and an access token naming the same user
    /// - When:
    ///    - It is verified with claim checks on
    /// - Then:
    ///    - Nothing is thrown
    ///
    func testMatchingClaimsPass() throws {
        XCTAssertNoThrow(try verify(idToken: idToken(), accessToken: accessToken(), policy: claimsOnly))
    }

    /// Test that the id token must be an id token
    ///
    /// - Given: A token whose `token_use` is `access`
    /// - When:
    ///    - It is verified as the id token
    /// - Then:
    ///    - `tokenUse` is thrown
    ///
    func testTokenUseMustBeId() {
        assertMismatch(.tokenUse, idToken: idToken(["token_use": "access"]))
        assertMismatch(.tokenUse, idToken: idToken(removing: "token_use"))
    }

    /// Test that the audience must be the hosted-UI client
    ///
    /// - Given: An id token for another client, and `aud` as an array with and without this client
    /// - When:
    ///    - Each is verified
    /// - Then:
    ///    - Another client throws `audience`; an array naming this client passes
    ///
    func testAudienceMustNameTheHostedUIClient() throws {
        assertMismatch(.audience, idToken: idToken(["aud": "anotherClient"]))
        assertMismatch(.audience, idToken: idToken(["aud": ["anotherClient"]]))
        assertMismatch(.audience, idToken: idToken(removing: "aud"))
        XCTAssertNoThrow(try verify(
            idToken: idToken(["aud": ["anotherClient", clientId]]),
            accessToken: accessToken(),
            policy: claimsOnly
        ))
    }

    /// Test that the issuer must be this user pool
    ///
    /// - Given: Id tokens issued by another pool, another region, a non-Cognito host, and the China
    ///   partition's host for this pool
    /// - When:
    ///    - Each is verified
    /// - Then:
    ///    - Only this pool passes, in either partition
    ///
    func testIssuerMustBeThisUserPool() throws {
        assertMismatch(.issuer, idToken: idToken(["iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_other"]))
        assertMismatch(.issuer, idToken: idToken(["iss": "https://cognito-idp.us-west-2.amazonaws.com/\(poolId)"]))
        assertMismatch(.issuer, idToken: idToken(["iss": "https://example.com/\(poolId)"]))
        assertMismatch(.issuer, idToken: idToken(removing: "iss"))
        XCTAssertNoThrow(try verify(
            idToken: idToken(["iss": "https://cognito-idp.\(region).amazonaws.com.cn/\(poolId)"]),
            accessToken: accessToken(),
            policy: claimsOnly
        ))
    }

    /// Test that the issuer's region is the pool's, not the configured one
    ///
    /// - Given: A pool in `eu-west-1` configured with region `us-east-1`, and a pool ID with no region prefix
    /// - When:
    ///    - Id tokens from each region are verified
    /// - Then:
    ///    - Only the pool's own region is accepted; without a prefix the configured region is used
    ///
    func testIssuerRegionComesFromThePoolID() throws {
        let euPool = "eu-west-1_pool"
        for (issuerRegion, accepted) in [("eu-west-1", true), ("us-east-1", false)] {
            let token = idToken(["iss": "https://cognito-idp.\(issuerRegion).amazonaws.com/\(euPool)"])
            let result = Result { try verify(idToken: token, policy: claimsOnly, userPoolId: euPool, region: "us-east-1") }
            XCTAssertEqual((try? result.get()) != nil, accepted, issuerRegion)
        }
        XCTAssertEqual(HostedUIIdentityVerifier.issuerRegion(userPoolId: euPool, configuredRegion: "x"), "eu-west-1")
        XCTAssertEqual(HostedUIIdentityVerifier.issuerRegion(userPoolId: "nopool", configuredRegion: "x"), "x")
        XCTAssertEqual(HostedUIIdentityVerifier.issuerRegion(userPoolId: "_pool", configuredRegion: "x"), "x")
    }

    /// Test that the nonce binds the response to this flow
    ///
    /// - Given: An id token with a different nonce, and one with none, for a flow that sent a nonce; and a
    ///   flow that sent none
    /// - When:
    ///    - Each is verified
    /// - Then:
    ///    - A different or absent nonce throws `nonce`; with no nonce sent there is nothing to compare
    ///
    func testNonceMustMatchWhenOneWasSent() throws {
        assertMismatch(.nonce, idToken: idToken(["nonce": "anotherFlow"]))
        assertMismatch(.nonce, idToken: idToken(removing: "nonce"))
        XCTAssertNoThrow(try verify(
            idToken: idToken(removing: "nonce"),
            accessToken: accessToken(),
            policy: claimsOnly,
            sendsNonce: false
        ))
    }

    /// Test that both tokens must name the same user
    ///
    /// - Given: An access token for another `sub`, and an access token that cannot be read, so the sign-in
    ///   would store `"unknown"`
    /// - When:
    ///    - Each is verified, with claim checks on and with only an expectation
    /// - Then:
    ///    - Both throw `subject`: the identity verified must be the identity stored
    ///
    func testVerifiedIdentityMustBeTheStoredIdentity() throws {
        for policy in [claimsOnly, HostedUIIdentityPolicy(verifiesTokenClaims: false, expectedIdentity: "user-sub")] {
            assertMismatch(.subject, accessToken: accessToken(["sub": "someoneElse"]), policy: policy)
            let mismatch = assertMismatch(.subject, accessToken: "opaque", policy: policy)
            XCTAssertEqual(mismatch?.returnedUserId, "user-sub")
        }
    }

    /// Test that the claim checks are skipped when only an expectation is set
    ///
    /// - Given: An id token for another client and pool, and a policy with only an expectation
    /// - When:
    ///    - It is verified
    /// - Then:
    ///    - Nothing is thrown, because claim checks are off
    ///
    func testClaimChecksAreOffWhenNotAsked() throws {
        let policy = HostedUIIdentityPolicy(verifiesTokenClaims: false, expectedIdentity: "user-sub")
        XCTAssertNoThrow(try verify(
            idToken: idToken(["aud": "other", "iss": "other", "token_use": "access", "nonce": "other"]),
            accessToken: accessToken(),
            policy: policy
        ))
    }

    // MARK: - The returned identity

    /// Test that a user must come back
    ///
    /// - Given: Id tokens with no `sub`, an empty `sub` and a non-string `sub`
    /// - When:
    ///    - Each is verified
    /// - Then:
    ///    - `missingIdentity` is thrown: no placeholder such as `"unknown"` is accepted as a user
    ///
    func testMissingSubjectIsRefusedNotReadAsUnknown() {
        assertMismatch(.missingIdentity, idToken: idToken(removing: "sub"), accessToken: accessToken(removing: "sub"))
        assertMismatch(.missingIdentity, idToken: idToken(["sub": ""]), accessToken: accessToken(removing: "sub"))
        assertMismatch(.missingIdentity, idToken: idToken(["sub": 42]), accessToken: accessToken(removing: "sub"))
    }

    /// Test that an expectation is met by the `sub` or the username
    ///
    /// - Given: Expectations naming the `sub`, the username the sign-in stores (the access token's), and, when
    ///   the access token has no username, the id token's `cognito:username`
    /// - When:
    ///    - Each is verified
    /// - Then:
    ///    - Each passes
    ///
    func testExpectationIsMetBySubOrUsername() throws {
        XCTAssertNoThrow(try verify(policy: expecting("user-sub")))
        XCTAssertNoThrow(try verify(policy: expecting("accessUsername")))
        XCTAssertNoThrow(try verify(accessToken: accessToken(removing: "username"), policy: expecting("idUsername")))
    }

    /// Test that another user fails the expectation
    ///
    /// - Given: An expectation naming another user, and one differing only in case
    /// - When:
    ///    - Each is verified
    /// - Then:
    ///    - `notExpectedIdentity` is thrown, carrying the expectation and the user that came back
    ///
    func testAnotherUserFailsTheExpectation() {
        let mismatch = assertMismatch(.notExpectedIdentity, policy: expecting("someoneElse"))
        XCTAssertEqual(mismatch?.expected, "someoneElse")
        XCTAssertEqual(mismatch?.returnedUserId, "user-sub")
        XCTAssertEqual(mismatch?.returnedUsername, "accessUsername")
        XCTAssertEqual(mismatch?.isIdentityMismatch, true)
        assertMismatch(.notExpectedIdentity, policy: expecting("ACCESSUSERNAME"))
    }

    /// Test that a user signed in to another session is refused
    ///
    /// - Given: Excluded subjects that include the returned `sub`, and ones that do not
    /// - When:
    ///    - Each is verified
    /// - Then:
    ///    - The first throws `signedInToAnotherSession`; the second passes
    ///
    func testUserSignedInToAnotherSessionIsRefused() throws {
        let excluded = HostedUIIdentityPolicy(verifiesTokenClaims: true, excludedSubjects: ["other-sub", "user-sub"])
        let mismatch = assertMismatch(.signedInToAnotherSession, policy: excluded)
        XCTAssertNil(mismatch?.expected)
        XCTAssertEqual(mismatch?.returnedUserId, "user-sub")

        let others = HostedUIIdentityPolicy(verifiesTokenClaims: true, excludedSubjects: ["other-sub"])
        XCTAssertNoThrow(try verify(policy: others))
    }

    /// Test that malformed id tokens are refused without trapping
    ///
    /// - Given: Id tokens with too few parts, a payload that is not base64, and a payload that is not a JSON
    ///   object
    /// - When:
    ///    - Each is verified under an active policy
    /// - Then:
    ///    - `tokenParsing` is thrown for each
    ///
    func testMalformedIdTokenThrowsTokenParsing() {
        let arrayPayload = Data("[1,2]".utf8).base64EncodedString()
        for token in ["", "a.b", "header.!!!.signature", "header.\(arrayPayload).signature"] {
            XCTAssertThrowsError(try verify(idToken: token, policy: claimsOnly), token) { error in
                XCTAssertEqual(error as? HostedUIError, .tokenParsing, token)
            }
        }
    }

    /// Test that base64url payloads decode with and without padding
    ///
    /// - Given: A payload whose base64url form uses `-` and `_` and whose padding is stripped
    /// - When:
    ///    - Its claims are read
    /// - Then:
    ///    - The claims decode
    ///
    func testClaimsDecodeBase64URLWithoutPadding() throws {
        let payload = Data(#"{"sub":"u1","x":"??>>"}"#.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        XCTAssertTrue(payload.contains("-") || payload.contains("_"))
        let claims = try XCTUnwrap(HostedUIIdentityVerifier.claims(of: "header.\(payload).signature"))
        XCTAssertEqual(claims["sub"] as? String, "u1")
        XCTAssertEqual(claims["x"] as? String, "??>>")
    }

    // MARK: - Helpers

    private var claimsOnly: HostedUIIdentityPolicy {
        HostedUIIdentityPolicy(verifiesTokenClaims: true)
    }

    private func expecting(_ identity: String) -> HostedUIIdentityPolicy {
        HostedUIIdentityPolicy(verifiesTokenClaims: true, expectedIdentity: identity)
    }

    /// Verifies as `FetchHostedUISignInToken` does: the stored identity is what `SignedInData` reads from the
    /// access token.
    private func verify(
        idToken: String? = nil,
        accessToken: String? = nil,
        policy: HostedUIIdentityPolicy,
        sendsNonce: Bool = true,
        userPoolId: String? = nil,
        region: String? = nil
    ) throws {
        let idToken = idToken ?? self.idToken()
        let stored = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: EngineUserPoolTokens(
                idToken: idToken,
                accessToken: accessToken ?? self.accessToken(),
                refreshToken: "refreshToken",
                expiresIn: 3_600
            )
        )
        try HostedUIIdentityVerifier.verify(
            idToken: idToken,
            storedUserId: stored.userId,
            storedUsername: stored.username,
            policy: policy,
            origin: .init(
                expectedNonce: sendsNonce ? nonce : nil,
                hostedUIClientId: clientId,
                userPoolId: userPoolId ?? poolId,
                region: region ?? self.region
            )
        )
    }

    @discardableResult
    private func assertMismatch(
        _ reason: HostedUIIdentityMismatch.Reason,
        idToken: String? = nil,
        accessToken: String? = nil,
        policy: HostedUIIdentityPolicy? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HostedUIIdentityMismatch? {
        var mismatch: HostedUIIdentityMismatch?
        XCTAssertThrowsError(
            try verify(idToken: idToken, accessToken: accessToken, policy: policy ?? claimsOnly),
            file: file,
            line: line
        ) { error in
            guard case .unexpectedIdentity(let thrown) = error as? HostedUIError else {
                XCTFail("Expected unexpectedIdentity(\(reason)), got \(error)", file: file, line: line)
                return
            }
            XCTAssertEqual(thrown.reason, reason, file: file, line: line)
            mismatch = thrown
        }
        return mismatch
    }

    private func idToken(_ overrides: [String: Any] = [:], removing removed: String? = nil) -> String {
        var claims: [String: Any] = [
            "sub": "user-sub",
            "cognito:username": "idUsername",
            "aud": clientId,
            "iss": "https://cognito-idp.\(region).amazonaws.com/\(poolId)",
            "token_use": "id",
            "nonce": nonce,
            "email": "user@example.com"
        ]
        claims.merge(overrides) { _, new in new }
        if let removed {
            claims[removed] = nil
        }
        return UnsignedJWT.make(claims)
    }

    private func accessToken(_ overrides: [String: Any] = [:], removing removed: String? = nil) -> String {
        var claims: [String: Any] = [
            "sub": "user-sub",
            "username": "accessUsername",
            "client_id": clientId,
            "token_use": "access"
        ]
        claims.merge(overrides) { _, new in new }
        if let removed {
            claims[removed] = nil
        }
        return UnsignedJWT.make(claims)
    }
}
