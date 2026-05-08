//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Standalone, instantiable AppSync GraphQL client. Supports queries, mutations, and
/// subscriptions with typed auth and per-client connection state.
///
/// Not a singleton — create multiple instances for multi-tenant / multi-API scenarios.
///
/// ```swift
/// let client = try AmplifyAppSyncClient(
///     configuration: .init(
///         endpoint: "https://xxx.appsync-api.us-east-1.amazonaws.com/graphql",
///         authorization: .single(.apiKey("da2-xxx"))
///     )
/// )
///
/// let response = try await client.query(request)
/// ```
public final class AmplifyAppSyncClient: Sendable {

    /// The configuration this client was created with.
    public let configuration: Configuration

    /// Creates a new AppSync client.
    ///
    /// - Parameter configuration: The client configuration including endpoint and authorization.
    /// - Throws: If the configuration is invalid (e.g., region cannot be inferred).
    public init(configuration: Configuration) throws {
        self.configuration = configuration
        // TODO: Initialize internal HTTP and WebSocket transports
    }

    // MARK: - Query

    /// Execute a GraphQL query.
    ///
    /// - Parameter request: The GraphQL request.
    /// - Returns: The typed GraphQL response.
    /// - Throws: `AppSyncError` or `AppSyncAuthError` on failure.
    public func query<T: Decodable & Sendable>(
        _ request: GraphQLRequest<T>
    ) async throws -> GraphQLResponse<T> {
        fatalError("Not yet implemented")
    }

    // MARK: - Mutation

    /// Execute a GraphQL mutation.
    ///
    /// - Parameter request: The GraphQL request.
    /// - Returns: The typed GraphQL response.
    /// - Throws: `AppSyncError` or `AppSyncAuthError` on failure.
    public func mutate<T: Decodable & Sendable>(
        _ request: GraphQLRequest<T>
    ) async throws -> GraphQLResponse<T> {
        fatalError("Not yet implemented")
    }

    // MARK: - Subscription

    /// Subscribe to a GraphQL subscription.
    ///
    /// The WebSocket connection is lazy (established on first subscribe) and shared across
    /// all subscriptions on this client. Cancelling the task terminates the subscription.
    ///
    /// - Parameter request: The GraphQL subscription request.
    /// - Returns: An async stream of subscription events.
    public func subscribe<T: Decodable & Sendable>(
        _ request: GraphQLRequest<T>
    ) -> AsyncThrowingStream<SubscriptionEvent<T>, Error> {
        fatalError("Not yet implemented")
    }

    // MARK: - Connection State

    /// Per-client WebSocket connection state.
    /// Emits `ConnectionState` changes for the shared WebSocket connection.
    public var connectionState: AsyncStream<ConnectionState> {
        fatalError("Not yet implemented")
    }

    // MARK: - Lifecycle

    /// Close the client. Terminates all active subscriptions and releases resources.
    /// The client cannot be reused after closing.
    public func close() {
        // TODO: Close HTTP and WebSocket transports
    }

    // MARK: - Configuration

    /// Configuration for `AmplifyAppSyncClient`.
    public struct Configuration: @unchecked Sendable {
        /// The AppSync GraphQL endpoint URL.
        public let endpoint: URL

        /// Auth configuration for the client.
        public let authorization: AppSyncAuthorization

        /// AWS region. Inferred from the endpoint URL if not provided.
        public let region: String

        /// Optional configurator for the URLSession used for HTTP requests.
        public let urlSessionConfiguration: URLSessionConfiguration?

        /// Creates a new configuration.
        ///
        /// - Parameters:
        ///   - endpoint: The AppSync GraphQL endpoint URL string.
        ///   - authorization: Auth configuration for the client.
        ///   - region: AWS region. If nil, inferred from the endpoint URL.
        ///   - urlSessionConfiguration: Optional URLSession configuration for HTTP requests.
        /// - Throws: If the endpoint is not a valid URL or region cannot be inferred.
        public init(
            endpoint: String,
            authorization: AppSyncAuthorization,
            region: String? = nil,
            urlSessionConfiguration: URLSessionConfiguration? = nil
        ) throws {
            guard let url = URL(string: endpoint) else {
                throw ConfigurationError.invalidEndpoint(endpoint)
            }
            let resolvedRegion = region ?? Self.inferRegion(from: endpoint)
            guard let resolvedRegion else {
                throw ConfigurationError.regionRequired
            }
            self.endpoint = url
            self.authorization = authorization
            self.region = resolvedRegion
            self.urlSessionConfiguration = urlSessionConfiguration
        }

        /// Infer the AWS region from an AppSync endpoint URL.
        /// Expected format: `https://{id}.appsync-api.{region}.amazonaws.com/graphql`
        static func inferRegion(from endpoint: String) -> String? {
            let pattern = #"\.appsync-api\.([a-z0-9-]+)\.amazonaws\.com"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(
                      in: endpoint,
                      range: NSRange(endpoint.startIndex..., in: endpoint)
                  ),
                  let range = Range(match.range(at: 1), in: endpoint) else {
                return nil
            }
            return String(endpoint[range])
        }
    }
}

// MARK: - Configuration Errors

public extension AmplifyAppSyncClient {
    /// Errors thrown during configuration validation.
    enum ConfigurationError: Error, Sendable {
        /// The endpoint string is not a valid URL.
        case invalidEndpoint(String)
        /// Region could not be inferred and was not provided.
        case regionRequired
    }
}
