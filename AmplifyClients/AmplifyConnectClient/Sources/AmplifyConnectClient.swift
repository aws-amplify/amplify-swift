//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import AmplifyFoundation
import AmplifyFoundationBridge
import AWSSDKHTTPAuth
import Foundation
import SmithyHTTPAPI
import SmithyHTTPAuth
import SmithyHTTPAuthAPI
import SmithyIdentity

/// A client for managing user profiles and device registrations
/// with Amazon Connect Customer Profiles.
///
/// Communicates with a Lambda-backed HTTP API endpoint.
///
/// ## Usage
///
/// ```swift
/// let config = try ConnectClientConfiguration.from()
/// let client = AmplifyConnectClient(
///     configuration: config,
///     credentialsProvider: myCredentialsProvider
/// )
///
/// try await client.identifyUser(
///     userId: "user-123",
///     userProfile: UserProfile(email: "user@example.com")
/// )
///
/// try await client.registerDevice(deviceToken: "apns-token")
/// ```
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
public struct AmplifyConnectClient: Sendable {
    private let configuration: ConnectClientConfiguration
    private nonisolated(unsafe) let credentialsProvider: any AWSCredentialsProvider
    private nonisolated(unsafe) let authTokenProvider: (any AuthTokenProvider)?
    private let urlSession: URLSession
    private let logger: Logger

    /// Initializes a new Connect client.
    /// - Parameters:
    ///   - configuration: Region and endpoint configuration. Use ``ConnectClientConfiguration/from(bundle:)``
    ///     to load from `amplify_outputs.json`.
    ///   - credentialsProvider: Credentials provider from the shared v3 foundation packages.
    ///   - authTokenProvider: Optional token provider for authenticated (signed-in) users.
    ///     If it returns a token, the authenticated path (Bearer) is used. If nil or returns nil,
    ///     falls back to the guest (SigV4) path using credentials.
    public init(
        configuration: ConnectClientConfiguration,
        credentialsProvider: any AWSCredentialsProvider,
        authTokenProvider: (any AuthTokenProvider)? = nil
    ) {
        self.configuration = configuration
        self.credentialsProvider = credentialsProvider
        self.authTokenProvider = authTokenProvider
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.urlCache = nil
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.urlSession = URLSession(configuration: sessionConfig)
        self.logger = AmplifyLogging.logger(for: AmplifyConnectClient.self)
    }

    /// Initializes a new Connect client with explicit region and endpoint.
    /// - Parameters:
    ///   - region: The AWS region.
    ///   - endpoint: The HTTP API endpoint URL (Lambda-backed).
    ///   - credentialsProvider: Credentials provider from the shared v3 foundation packages.
    ///   - authTokenProvider: Optional token provider for authenticated (signed-in) users.
    public init(
        region: String,
        endpoint: String,
        credentialsProvider: any AWSCredentialsProvider,
        authTokenProvider: (any AuthTokenProvider)? = nil
    ) {
        self.init(
            configuration: ConnectClientConfiguration(region: region, endpoint: endpoint),
            credentialsProvider: credentialsProvider,
            authTokenProvider: authTokenProvider
        )
    }

    // MARK: - Public API

    /// Creates or updates the user's Connect Customer Profile with targeting attributes.
    ///
    /// First call for a new user creates the profile and establishes the
    /// Cognito identity link. Subsequent calls update attributes.
    ///
    /// - Parameters:
    ///   - userId: The user identifier (typically the Cognito sub).
    ///   - userProfile: Optional user profile attributes to set.
    ///   - options: Additional options (device info, channel type, merge-on-sign-in).
    public func identifyUser(
        userId: String,
        userProfile: UserProfile = UserProfile(),
        options: IdentifyUserOptions? = nil
    ) async throws {
        let request = IdentifyUserRequest(
            userId: userId,
            userProfile: userProfile,
            options: options
        )
        try await sendRequest(request)
        logger.verbose("identifyUser succeeded for userId: \(userId)")
    }

    // MARK: - Private

    private func sendRequest<T: Encodable>(_ body: T) async throws {
        let encoder = JSONEncoder()
        let data: Data
        do {
            data = try encoder.encode(body)
        } catch {
            throw ConnectError.service(
                "Failed to encode request body",
                "Verify that input values are JSON-serializable.",
                error
            )
        }

        if let tokenProvider = authTokenProvider,
           let token = try await tokenProvider.getToken() {
            try await sendAuthenticated(data: data, accessToken: token.accessToken)
        } else {
            let credentials: AWSCredentials
            do {
                credentials = try await credentialsProvider.resolve()
            } catch {
                throw ConnectError.credentials(
                    "Failed to resolve credentials",
                    "Ensure credentials provider is properly configured.",
                    error
                )
            }
            try await sendGuest(data: data, credentials: credentials)
        }
    }

    private var userAgent: String {
        "lib/\(AmplifyMetadata.platformName)#\(AmplifyMetadata.version) md/amplify-connect"
    }

    private func sendAuthenticated(data: Data, accessToken: String) async throws {
        guard let url = URL(string: "\(configuration.endpoint)/identify-user") else {
            throw ConnectError.configuration(
                "Invalid endpoint URL: \(configuration.endpoint)",
                "Provide a valid URL in ConnectClientConfiguration."
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = data

        logger.debug("Sending authenticated request to /identify-user")
        try await execute(request)
    }

    private func sendGuest(data: Data, credentials: AWSCredentials) async throws {
        guard let url = URL(string: "\(configuration.endpoint)/identify-user-guest"),
              let host = url.host
        else {
            throw ConnectError.configuration(
                "Invalid endpoint URL: \(configuration.endpoint)",
                "Provide a valid URL in ConnectClientConfiguration."
            )
        }

        let requestBuilder = HTTPRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withMethod(.post)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(["Content-Type": "application/json", "User-Agent": userAgent]))
            .withBody(.data(data))

        let identity = AWSCredentialIdentity(
            accessKey: credentials.accessKeyId,
            secret: credentials.secretAccessKey,
            sessionToken: (credentials as? AWSTemporaryCredentials)?.sessionToken
        )

        let flags = SigningFlags(
            useDoubleURIEncode: true,
            shouldNormalizeURIPath: true,
            omitSessionToken: false
        )
        let signingConfig = AWSSigningConfig(
            credentials: identity,
            signedBodyHeader: .none,
            signedBodyValue: .empty,
            flags: flags,
            date: Date(),
            service: "execute-api",
            region: configuration.region,
            signatureType: .requestHeaders,
            signingAlgorithm: .sigv4
        )

        let signer = AWSSigV4Signer()
        guard let signedRequest = await signer.sigV4SignedRequest(
            requestBuilder: requestBuilder,
            signingConfig: signingConfig
        ) else {
            throw ConnectError.service(
                "Failed to sign request",
                "Check that credentials are valid."
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        for header in signedRequest.headers.headers {
            request.setValue(header.value.joined(separator: ","), forHTTPHeaderField: header.name)
        }

        logger.debug("Sending guest request to /identify-user-guest (SigV4)")
        try await execute(request)
    }

    private func execute(_ request: URLRequest) async throws {
        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await urlSession.data(for: request)
        } catch {
            throw ConnectError.service(
                "Network request failed",
                "Check network connectivity and endpoint URL.",
                error
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConnectError.service(
                "Invalid response received",
                "The server returned a non-HTTP response."
            )
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw ConnectError.service(
                "Request failed with status \(httpResponse.statusCode)",
                "Check the endpoint configuration and request payload."
            )
        }
    }
}
