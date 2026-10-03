//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Differential tests: `EngineJWT.claims(_:)` must behave exactly like
/// `AWSAuthService().getTokenClaims(tokenString:)`, which it replaces in the engine.
class EngineJWTTests: XCTestCase {

    /// Every token shape the decoder distinguishes: valid (padded, unpadded, base64url alphabet,
    /// extra segments, nested and unicode claims), malformed (too few segments, empty segments,
    /// not base64, not JSON, JSON that is not an object) and edge cases.
    private static let corpus: [(name: String, token: String)] = [
        ("cognito-like id token", token(#"{"sub":"8f2e","exp":1700000000,"iat":1699996400,"cognito:username":"alice","email_verified":true}"#)),
        ("payload needing one pad", token(#"{"a":"bc"}"#)),
        ("payload needing two pads", token(#"{"ab":1}"#)),
        ("payload needing no pad", token(#"{"abc":12}"#)),
        ("payload already padded", token(#"{"ab":1}"#, padded: true)),
        ("base64url alphabet (- and _)", token(#"{"x":"???>>>~~~"}"#)),
        ("standard alphabet (+ and /)", token(#"{"x":"???>>>~~~"}"#, urlSafe: false)),
        ("nested claims", token(#"{"exp":1.5,"groups":["a","b"],"meta":{"k":null,"n":-3}}"#)),
        ("unicode claims", token(#"{"name":"Zoë 🦊","loc":"東京"}"#)),
        ("empty object", token("{}")),
        ("four segments", token(#"{"exp":42}"#) + ".extra"),
        ("empty signature segment", "e30." + base64URL(#"{"exp":1}"#) + "."),
        ("empty token", ""),
        ("one segment", "abc"),
        ("two segments", "header." + base64URL(#"{"exp":1}"#)),
        ("empty middle segment", "a..c"),
        ("only dots", "..."),
        ("payload not base64 (length 1 mod 4)", "a.abcde.c"),
        ("payload with unknown characters", "a." + base64URL(#"{"exp":7}"#) + "!!*.c"),
        ("payload only unknown characters", "a.!!!!.c"),
        ("payload not JSON", "a." + base64URL("hello world") + ".c"),
        ("payload JSON array", "a." + base64URL("[1,2,3]") + ".c"),
        ("payload JSON string fragment", "a." + base64URL(#""just a string""#) + ".c"),
        ("payload JSON number fragment", "a." + base64URL("42") + ".c"),
        ("payload truncated JSON", "a." + base64URL(#"{"exp":"#) + ".c"),
        ("payload with whitespace", "a." + base64URL(" { \"exp\" : 3 } ") + ".c"),
        ("leading dot", "." + base64URL(#"{"exp":1}"#) + ".sig.x")
    ]

    /// - Given: The token corpus
    /// - When: Each token is decoded by `EngineJWT` and by `AWSAuthService`
    /// - Then:
    ///    - Both succeed or both fail
    ///    - On success the claims are equal
    ///    - On failure the message and the underlying error are equal
    ///
    func testClaimsMatchAWSAuthServiceOverCorpus() {
        var successes = 0
        var failures = 0
        for (name, token) in Self.corpus {
            let expected = AWSAuthService().getTokenClaims(tokenString: token)
            let actual = EngineJWT.claims(token)
            switch (expected, actual) {
            case (.success(let expectedClaims), .success(let actualClaims)):
                successes += 1
                XCTAssertTrue(
                    NSDictionary(dictionary: expectedClaims).isEqual(to: actualClaims),
                    "\(name): claims differ, expected \(expectedClaims), got \(actualClaims)"
                )
            case (.failure(let expectedError), .failure(let actualFailure)):
                failures += 1
                guard case .validation(let field, let description, let suggestion, let underlying) = expectedError else {
                    XCTFail("\(name): AWSAuthService returned a non-validation error \(expectedError)")
                    continue
                }
                XCTAssertEqual(field, "", name)
                XCTAssertEqual(suggestion, "", name)
                XCTAssertEqual(description, actualFailure.message, name)
                XCTAssertEqual(underlying.map { ($0 as NSError).domain }, actualFailure.underlyingError.map { ($0 as NSError).domain }, name)
                XCTAssertEqual(underlying.map { ($0 as NSError).code }, actualFailure.underlyingError.map { ($0 as NSError).code }, name)
            case (.success, .failure(let failure)):
                XCTFail("\(name): AWSAuthService succeeded, EngineJWT failed with \(failure)")
            case (.failure(let error), .success):
                XCTFail("\(name): AWSAuthService failed with \(error), EngineJWT succeeded")
            }
        }
        // Guards against a corpus that silently stopped exercising one side.
        XCTAssertGreaterThanOrEqual(successes, 12)
        XCTAssertGreaterThanOrEqual(failures, 10)
    }

    /// - Given: The token corpus
    /// - When: `exp` is read the way `AWSCognitoUserPoolTokens` and `areTokensExpiring` read it
    /// - Then: `EngineJWT` gives the same value as `AWSAuthService`
    ///
    func testExpirationClaimMatchesAWSAuthService() {
        for (name, token) in Self.corpus {
            let expected = (try? AWSAuthService().getTokenClaims(tokenString: token).get())?["exp"]?.doubleValue
            let actual = (try? EngineJWT.claims(token).get())?["exp"]?.doubleValue
            XCTAssertEqual(expected, actual, name)
        }
    }

    /// - Given: Each failure case
    /// - When: Its message is read
    /// - Then: It is the literal `AWSAuthService` uses for that failure
    ///
    func testFailureMessages() {
        XCTAssertEqual(EngineJWT.Failure.malformedToken.message, "Token is not valid base64 encoded string.")
        XCTAssertEqual(
            EngineJWT.Failure.invalidBase64.message,
            "Cannot get claims in `Data` form. Token is not valid base64 encoded string."
        )
        XCTAssertEqual(
            EngineJWT.Failure.invalidJSON(NSError(domain: "d", code: 1)).message,
            "Cannot get claims in `Data` form. Token is not valid JSON string."
        )
        XCTAssertEqual(
            EngineJWT.Failure.notAnObject.message,
            "Cannot get claims in `Data` form. Unable to convert to [String: AnyObject]."
        )
        XCTAssertNil(EngineJWT.Failure.malformedToken.underlyingError)
        XCTAssertNotNil(EngineJWT.Failure.invalidJSON(NSError(domain: "d", code: 1)).underlyingError)
    }

    // MARK: - Helpers

    private static func token(_ payloadJSON: String, padded: Bool = false, urlSafe: Bool = true) -> String {
        let header = base64URL(#"{"alg":"RS256","kid":"k"}"#)
        let payload = urlSafe ? base64URL(payloadJSON, padded: padded) : base64(payloadJSON, padded: padded)
        return "\(header).\(payload).c2lnbmF0dXJl"
    }

    private static func base64(_ text: String, padded: Bool = false) -> String {
        let encoded = Data(text.utf8).base64EncodedString()
        return padded ? encoded : encoded.replacingOccurrences(of: "=", with: "")
    }

    private static func base64URL(_ text: String, padded: Bool = false) -> String {
        base64(text, padded: padded)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
