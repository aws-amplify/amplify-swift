//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AWSCognitoIdentityProvider
import Foundation
import SmithyHTTPAPI

/// Records the `X-Amz-Target` and `User-Agent` of every request a session's user pool client sends, and the
/// request body's `AuthFlow`, `ChallengeName` and `ClientMetadata`, and the first-factor names of a
/// choice-based sign-in (the preferred challenge, and a `SELECT_CHALLENGE` answer). Nothing else of the body
/// is kept: no password, token, code, custom answer or SRP value.
///
/// Install it through the client's escape hatch:
///
/// ```swift
/// let recorder = RecordingHTTPClient()
/// let client = try AmplifyCognitoClient(
///     configuration: configuration,
///     options: .init(sessionId: id, configureUserPoolClient: recorder.configureUserPoolClient)
/// )
/// ```
///
/// The client wraps whatever engine the closure leaves in the user-agent engine, so this recorder
/// sits inside it and sees the final `User-Agent`. It only records; every request still goes to the
/// engine the SDK configured.
final class RecordingHTTPClient: Sendable {

    struct Request: Sendable, Equatable {
        /// The `X-Amz-Target` header, for example `AWSCognitoIdentityProviderService.InitiateAuth`.
        let target: String?
        let userAgent: String?
        /// The body's `AuthFlow` (`InitiateAuth`), for example `USER_SRP_AUTH`.
        var authFlow: String?
        /// The body's `ChallengeName` (`RespondToAuthChallenge`), for example `PASSWORD_VERIFIER`.
        var challengeName: String?
        /// The body's `AuthParameters.PREFERRED_CHALLENGE` (`InitiateAuth` with `USER_AUTH`), for example
        /// `EMAIL_OTP`. A factor name, never a secret.
        var preferredChallenge: String?
        /// The first factor a `SELECT_CHALLENGE` answer chose (its `ChallengeResponses.ANSWER`), for example
        /// `PASSWORD_SRP`. Read for that challenge only: another challenge's `ANSWER` can be a secret, such
        /// as a custom challenge's answer, and is never kept. An answer that is not a first-factor name is
        /// kept as `"<other>"`.
        var selectedChallenge: String?
        /// Whether this attempt failed in a way the SDK retries: no response (the connection was lost, but
        /// not a cancel), a 5xx or 408, or a throttling or transient error code. The SDK then sends the
        /// same request again, which is recorded again.
        var failedTransiently = false
        /// The body's `ClientMetadata` (`InitiateAuth`, `RespondToAuthChallenge`): what the app passed to the
        /// pool's Lambda triggers, never a secret.
        var clientMetadata: [String: String]?

        /// The operation name: the part of `target` after the last `.`.
        var operation: String? {
            target?.split(separator: ".").last.map(String.init)
        }
    }

    private let recorded = Recorded()

    init() {}

    /// Every request recorded so far, in the order sent.
    var requests: [Request] {
        recorded.snapshot()
    }

    /// The operation names recorded so far, in the order sent.
    var operations: [String] {
        requests.compactMap(\.operation)
    }

    /// The requests Cognito answered, in the order sent: `requests` without the attempts the SDK retried
    /// (`failedTransiently`), so a test that checks what the client asked for is not failed by a lost
    /// connection. An attempt still in flight is included.
    var answered: [Request] {
        requests.filter { !$0.failedTransiently }
    }

    func reset() {
        recorded.removeAll()
    }

    /// The escape-hatch closure that installs the recorder on a user pool client's configuration.
    var configureUserPoolClient: AmplifyCognitoClientUserPoolConfigurationProvider {
        { [recorded] config in
            config.httpClientEngine = Engine(target: config.httpClientEngine, recorded: recorded)
        }
    }

    private struct Engine: HTTPClient {
        let target: HTTPClient
        let recorded: Recorded

        func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
            var fields: [String: Any] = [:]
            if case .data(let data?) = request.body,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                fields = json
            }
            let id = recorded.append(Request(
                target: request.headers.value(for: "X-Amz-Target"),
                userAgent: request.headers.value(for: "User-Agent"),
                authFlow: fields["AuthFlow"] as? String,
                challengeName: fields["ChallengeName"] as? String,
                preferredChallenge: (fields["AuthParameters"] as? [String: Any])?["PREFERRED_CHALLENGE"] as? String,
                selectedChallenge: Self.selectedChallenge(in: fields),
                clientMetadata: fields["ClientMetadata"] as? [String: String]
            ))
            let response: SmithyHTTPAPI.HTTPResponse
            do {
                response = try await target.send(request: request)
            } catch {
                if Self.isRetried(error) {
                    recorded.markFailedTransiently(id)
                }
                throw error
            }
            if Self.isRetried(response) {
                recorded.markFailedTransiently(id)
            }
            return response
        }

        /// A transport failure the SDK sends again. `DefaultRetryErrorInfoProvider` retries only transient
        /// connection failures, and a cancelled request never; the rest end the call, and so the test.
        private static func isRetried(_ error: Error) -> Bool {
            if error is CancellationError {
                return false
            }
            let nsError = error as NSError
            return !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled)
        }

        /// An answer the SDK sends again, as `AWSRetryErrorInfoProvider` classifies it: HTTP 500, 502,
        /// 503, 504 or 408, or an error type among its throttling and transient codes (Cognito's
        /// `LimitExceededException` and `TooManyRequestsException` among them).
        private static func isRetried(_ response: SmithyHTTPAPI.HTTPResponse) -> Bool {
            if [500, 502, 503, 504, 408].contains(response.statusCode.rawValue) {
                return true
            }
            // `X-Amzn-ErrorType` is `Code` or `Code:detail`.
            let errorType = response.headers.value(for: "X-Amzn-ErrorType")?
                .split(separator: ":").first.map(String.init) ?? ""
            return retriedErrorCodes.contains(errorType)
        }

        /// `AWSRetryErrorInfoProvider`'s throttling and transient error codes.
        private static let retriedErrorCodes: Set<String> = [
            "Throttling", "ThrottlingException", "ThrottledException", "RequestThrottledException",
            "TooManyRequestsException", "ProvisionedThroughputExceededException", "TransactionInProgressException",
            "RequestLimitExceeded", "BandwidthLimitExceeded", "LimitExceededException", "RequestThrottled",
            "SlowDown", "PriorRequestNotComplete", "EC2ThrottledException",
            "RequestTimeout", "InternalError", "RequestTimeoutException"
        ]

        /// `ChallengeResponses.ANSWER` of a `SELECT_CHALLENGE` answer when it is a first-factor name, else
        /// `otherSelection`; nothing for any other body. A client bug that sent something else there (a
        /// password, a code) is then never kept, so no assertion can print it.
        private static func selectedChallenge(in fields: [String: Any]) -> String? {
            guard fields["ChallengeName"] as? String == "SELECT_CHALLENGE" else {
                return nil
            }
            guard let answer = (fields["ChallengeResponses"] as? [String: Any])?["ANSWER"] as? String else {
                return nil
            }
            return firstFactorNames.contains(answer) ? answer : otherSelection
        }

        /// The names a `SELECT_CHALLENGE` answer may carry.
        private static let firstFactorNames: Set<String> = ["PASSWORD", "PASSWORD_SRP", "SMS_OTP", "EMAIL_OTP", "WEB_AUTHN"]

        /// What `Request.selectedChallenge` holds when a `SELECT_CHALLENGE` answer was not a first-factor
        /// name.
        static let otherSelection = "<other>"
    }

    private final class Recorded: @unchecked Sendable {
        private let lock = NSLock()
        private var requests: [(id: UUID, request: Request)] = []

        /// Records `request` and returns its identity, for `markFailedTransiently(_:)`.
        func append(_ request: Request) -> UUID {
            let id = UUID()
            lock.withLock { requests.append((id, request)) }
            return id
        }

        /// Marks a recorded attempt as retried; a no-op once `removeAll` dropped it.
        func markFailedTransiently(_ id: UUID) {
            lock.withLock {
                if let index = requests.firstIndex(where: { $0.id == id }) {
                    requests[index].request.failedTransiently = true
                }
            }
        }

        func snapshot() -> [Request] {
            lock.withLock { requests.map(\.request) }
        }

        func removeAll() {
            lock.withLock { requests.removeAll() }
        }
    }
}
