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
import Smithy
import SmithyHTTPAPI
import SmithyHTTPAuth
import SmithyHTTPAuthAPI
import SmithyIdentity

/// A client for managing user profiles and device registrations
/// with Amazon Connect Customer Profiles.
///
/// Communicates with a Lambda-backed HTTP API endpoint. All requests are
/// SigV4-signed with the caller's AWS credentials (authenticated or guest);
/// the backend derives the caller identity from the signature.
///
/// ## Usage
///
/// ```swift
/// let config = try ConnectClientConfiguration()
/// let client = AmplifyConnectClient(
///     configuration: config,
///     credentialsProvider: myCredentialsProvider
/// )
///
/// try await client.identifyUser(
///     userProfile: UserProfile(email: "user@example.com")
/// )
///
/// try await client.registerDevice(token: "apns-device-token")
///
/// try await client.removeDevice()
/// ```
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
public struct AmplifyConnectClient: Sendable {
    private let configuration: ConnectClientConfiguration
    private nonisolated(unsafe) let credentialsProvider: any AWSCredentialsProvider
    private let urlSession: URLSession
    private let logger: Logger

    /// Initializes a new Connect client.
    /// - Parameters:
    ///   - configuration: Region and endpoint configuration. Use ``ConnectClientConfiguration/init(from:bundle:)``
    ///     to load from `amplify_outputs.json`.
    ///   - credentialsProvider: Credentials provider from the shared v3 foundation packages.
    public init(
        configuration: ConnectClientConfiguration,
        credentialsProvider: any AWSCredentialsProvider
    ) {
        self.configuration = configuration
        self.credentialsProvider = credentialsProvider
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
    public init(
        region: String,
        endpoint: String,
        credentialsProvider: any AWSCredentialsProvider
    ) {
        self.init(
            configuration: ConnectClientConfiguration(region: region, endpoint: endpoint),
            credentialsProvider: credentialsProvider
        )
    }

    // MARK: - Public API

    /// Creates or updates the caller's Connect Customer Profile with targeting attributes.
    ///
    /// The first call for a new identity creates the profile; subsequent calls
    /// update attributes. The profile identity is derived server-side from the
    /// request signature.
    ///
    /// - Parameter userProfile: User profile attributes to set.
    public func identifyUser(userProfile: UserProfile) async throws {
        try ConnectClientValidator.validate(userProfile)
        try await send(IdentifyUserRequest(userProfile: userProfile), to: "identify-user")
        logger.verbose("identifyUser succeeded")
    }

    /// Registers this device for push notifications on the caller's profile.
    ///
    /// The device identifier, platform, app version, and channel type are
    /// resolved automatically:
    /// - `deviceId`: stable per-install identifier shared across Amplify packages.
    /// - `platform`: the current operating system.
    /// - `appVersion`: the host app's `CFBundleShortVersionString`, if present.
    /// - `channelType`: `APNS_SANDBOX` for debug builds, `APNS` otherwise.
    ///
    /// - Parameter token: The APNs device token.
    public func registerDevice(token: String) async throws {
        try ConnectClientValidator.validateToken(token)
        let device = Device(
            token: token,
            deviceId: DeviceIdProvider.resolve(),
            platform: Self.platformName,
            appVersion: Self.appVersion,
            channelType: Self.channelType
        )
        try await send(RegisterDeviceRequest(device: device), to: "register-device")
        logger.verbose("registerDevice succeeded")
    }

    /// Removes this device's push registration from the caller's profile.
    ///
    /// Uses the same stable per-install device identifier that
    /// ``registerDevice(token:)`` registers.
    public func removeDevice() async throws {
        let deviceId = DeviceIdProvider.resolve()
        try await send(RemoveDeviceRequest(deviceId: deviceId), to: "remove-device")
        logger.verbose("removeDevice succeeded")
    }

    // MARK: - Device context

    /// The current operating system name, sent as the `platform` field.
    static var platformName: String {
        #if os(visionOS)
        return "visionOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "unknown"
        #endif
    }

    /// The host app's marketing version, if available.
    static var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    /// The push channel type. Debug builds use the APNs sandbox environment.
    static var channelType: ChannelType {
        #if DEBUG
        return .apnsSandbox
        #else
        return .apns
        #endif
    }

    // MARK: - Private

    private func send(_ body: some Encodable, to route: String) async throws {
        try ConnectClientConfiguration.validateEndpoint(configuration.endpoint)

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

        guard let url = URL(string: "\(configuration.endpoint)/\(route)"),
              let host = url.host,
              let scheme = url.scheme.flatMap({ URIScheme(rawValue: $0.lowercased()) })
        else {
            throw ConnectError.configuration(
                "Invalid endpoint URL: \(configuration.endpoint)",
                "Provide a valid URL in ConnectClientConfiguration."
            )
        }

        // Derive host, port, and protocol from the endpoint URL so the
        // signature is always computed over the same authority the request
        // is sent to.
        let port = url.port.flatMap { UInt16(exactly: $0) } ?? UInt16(scheme.port)

        let requestBuilder = HTTPRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withMethod(.post)
            .withPort(port)
            .withProtocol(scheme)
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

        logger.debug("Sending SigV4-signed request to /\(route)")
        try await execute(request)
    }

    private var userAgent: String {
        "lib/\(AmplifyMetadata.platformName)#\(AmplifyMetadata.version) md/amplify-connect"
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
