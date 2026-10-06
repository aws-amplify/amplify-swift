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

/// Records the operation name (the `X-Amz-Target` suffix) of every request a session's user pool client
/// sends, and nothing else. The operation-only part of `CognitoClientIntegrationTests`' `RecordingHTTPClient`,
/// which this target cannot see. A request without an `X-Amz-Target` header (no user pool operation sends
/// one, but a custom engine might) is recorded as `"?"`, so it still counts against "0 requests".
///
/// Install it with `Options(configureUserPoolClient: recorder.configureUserPoolClient)`.
final class UserPoolRequestRecorder: Sendable {

    private let recorded = Recorded()

    /// The operation names recorded so far, in the order sent, for example `InitiateAuth`.
    var operations: [String] {
        recorded.snapshot()
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
            let operation = request.headers.value(for: "X-Amz-Target")?.split(separator: ".").last.map(String.init)
            // `"?"`: a request without `X-Amz-Target` is still a request.
            recorded.append(operation ?? "?")
            return try await target.send(request: request)
        }
    }

    private final class Recorded: @unchecked Sendable {
        private let lock = NSLock()
        private var operations: [String] = []

        func append(_ operation: String) {
            lock.withLock { operations.append(operation) }
        }

        func snapshot() -> [String] {
            lock.withLock { operations }
        }
    }
}
