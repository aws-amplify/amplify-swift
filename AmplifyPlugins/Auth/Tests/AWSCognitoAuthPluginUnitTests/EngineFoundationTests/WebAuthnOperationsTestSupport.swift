//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Amplify.AuthError
import struct AWSCognitoIdentityProvider.InternalErrorException
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

/// Asserts `body` throws a Cognito exception's `WebAuthnCredentialOperations.Failure`: its engine error is
/// `.service` with `code` underneath, and its cause the exception, whose own engine error that is.
func assertEngineServiceError(
    code: EngineServiceErrorCode,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> Void
) async {
    do {
        try await body()
        XCTFail("Should have failed", file: file, line: line)
    } catch let failure as WebAuthnCredentialOperations.Failure {
        let error = failure.engineError
        guard case .service(_, _, let underlyingError) = error else {
            return XCTFail("Expected EngineAuthError.service, got \(error)", file: file, line: line)
        }
        XCTAssertEqual(underlyingError as? EngineServiceErrorCode, code, file: file, line: line)
        XCTAssertEqual((failure.cause as? EngineAuthErrorConvertible)?.engineError, error, file: file, line: line)
    } catch {
        XCTFail("Expected WebAuthnCredentialOperations.Failure, got \(error)", file: file, line: line)
    }
}

/// Asserts `body` throws `WebAuthnError.unknown`'s engine error with `description` over a `CancellationError`: as
/// an `EngineAuthError` (the ceremony body's, through the runner) or a `WebAuthnCredentialOperations.Failure`.
func assertUnknownServiceError(
    _ description: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> Void
) async {
    do {
        try await body()
        XCTFail("Should have failed", file: file, line: line)
    } catch let thrown as EngineAuthErrorConvertible {
        let error = thrown.engineError
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

/// Asserts `body` throws the `WebAuthnCredentialOperations.Failure` of `exception`, an `InternalErrorException`
/// with the message "boom": its engine error is the exception's own `.unknown`, with nothing underneath, its cause
/// the exception, and the plugin bridges it to the `AuthError` it bridges the exception to.
func assertInternalErrorFailure(
    _ exception: InternalErrorException,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> Void
) async {
    do {
        try await body()
        XCTFail("Should have failed", file: file, line: line)
    } catch let failure as WebAuthnCredentialOperations.Failure {
        guard case .unknown(let message, let underlying) = failure.engineError else {
            return XCTFail("Expected EngineAuthError.unknown, got \(failure.engineError)", file: file, line: line)
        }
        XCTAssertEqual(message, "boom", file: file, line: line)
        XCTAssertNil(underlying, file: file, line: line)
        XCTAssertTrue(failure.cause is InternalErrorException, "\(failure.cause)", file: file, line: line)
        guard let bridged = AuthError(converting: failure), let former = AuthError(converting: exception) else {
            return XCTFail("The plugin does not bridge \(failure)", file: file, line: line)
        }
        XCTAssertEqual(authErrorFingerprint(bridged), authErrorFingerprint(former), file: file, line: line)
    } catch {
        XCTFail("Expected WebAuthnCredentialOperations.Failure, got \(error)", file: file, line: line)
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
