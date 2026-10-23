//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Amplify.AuthError
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

// Shared by `WebAuthnCredentialOperationsTests` and `WebAuthnAssociateOperationTests`.

enum CallerOwnedError: Error, Equatable {
    case token, userPool
}

struct WebAuthnListInput: Equatable {
    let accessToken: String?
    let maxResults: Int?
    let nextToken: String?

    init(_ accessToken: String?, _ maxResults: Int?, _ nextToken: String?) {
        self.accessToken = accessToken
        self.maxResults = maxResults
        self.nextToken = nextToken
    }
}

/// The caller's side of an operation: a mock user pool, and closures that record their calls.
///
/// - Note: a class, because `MockIdentityProvider` is a struct: `userPool()` hands out the mock as it is
///   when the operation asks for it, after the test has set its responses. `@unchecked Sendable`: each
///   test runs alone, and sets the mock before running the operation.
final class WebAuthnOperationsFixture: @unchecked Sendable {
    var identityProvider = MockIdentityProvider()
    /// Every token handed out, in order.
    let tokens = TestBox<[String]>([])
    let userPoolCalls = TestCounter()

    /// Hands out `token-1`, `token-2`, … and records each.
    func accessToken() -> WebAuthnCredentialOperations.AccessTokenProvider {
        let tokens = tokens
        return {
            var token = ""
            tokens.with {
                token = "token-\($0.count + 1)"
                $0.append(token)
            }
            return token
        }
    }

    func userPool() -> UserPoolEnvironment.CognitoUserPoolFactory {
        return {
            self.userPoolCalls.increment()
            return self.identityProvider
        }
    }
}

/// An `AuthError`'s case, strings and underlying error (type, domain and code), for comparing two of them.
func authErrorFingerprint(_ error: AuthError) -> [String] {
    [
        Mirror(reflecting: error).children.first?.label ?? "",
        error.errorDescription,
        error.recoverySuggestion,
        error.underlyingError.map { String(reflecting: type(of: $0)) } ?? "nil",
        error.underlyingError.map { "\(($0 as NSError).domain)/\(($0 as NSError).code)" } ?? "nil"
    ]
}

func assertEngineServiceError(
    code: EngineServiceErrorCode,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> Void
) async {
    do {
        try await body()
        XCTFail("Should have failed", file: file, line: line)
    } catch let error as EngineAuthError {
        guard case .service(_, _, let underlyingError) = error else {
            return XCTFail("Expected EngineAuthError.service, got \(error)", file: file, line: line)
        }
        XCTAssertEqual(underlyingError as? EngineServiceErrorCode, code, file: file, line: line)
    } catch {
        XCTFail("Expected EngineAuthError, got \(error)", file: file, line: line)
    }
}

func assertUnknownServiceError(
    _ description: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> Void
) async {
    do {
        try await body()
        XCTFail("Should have failed", file: file, line: line)
    } catch let error as EngineAuthError {
        guard case .service(let actual, _, let underlyingError) = error else {
            return XCTFail("Expected EngineAuthError.service, got \(error)", file: file, line: line)
        }
        XCTAssertEqual(actual, description, file: file, line: line)
        XCTAssertTrue(
            underlyingError is CancellationError,
            "\(String(describing: underlyingError))",
            file: file,
            line: line
        )
    } catch {
        XCTFail("Expected EngineAuthError, got \(error)", file: file, line: line)
    }
}

func assertCallerError(
    _ expected: CallerOwnedError,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> Void
) async {
    do {
        try await body()
        XCTFail("Should have failed", file: file, line: line)
    } catch let error as CallerOwnedError {
        XCTAssertEqual(error, expected, file: file, line: line)
    } catch {
        XCTFail("Expected the caller's own error, got \(error)", file: file, line: line)
    }
}
