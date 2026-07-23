//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Configuration for ``AmplifyConnectClient``.
///
/// Can be created manually or loaded from `amplify_outputs.json`
/// via ``init(from:bundle:)``.
public struct ConnectClientConfiguration: Sendable {
    /// The AWS region.
    public let region: String

    /// The HTTP API endpoint URL (Lambda-backed).
    public let endpoint: String

    public init(region: String, endpoint: String) {
        self.region = region
        self.endpoint = endpoint
    }

    /// Loads configuration from a JSON resource file in the given bundle.
    ///
    /// Reads the `notifications.amazon_connect_customer_profiles` key.
    ///
    /// - Parameters:
    ///   - resource: The resource file name (without extension). Defaults to `"amplify_outputs"`.
    ///   - bundle: The bundle containing the resource. Defaults to `.main`.
    /// - Throws: ``ConnectError/configuration(_:_:_:)`` if the file or keys are missing.
    public init(from resource: String = "amplify_outputs", bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw ConnectError.configuration(
                "\(resource).json not found in bundle",
                "Add \(resource).json to your app target."
            )
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ConnectError.configuration(
                "Failed to read \(resource).json",
                "Ensure the file is valid and accessible.",
                error
            )
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let notifications = json["notifications"] as? [String: Any],
              let customerProfiles = notifications["amazon_connect_customer_profiles"] as? [String: Any],
              let region = customerProfiles["aws_region"] as? String,
              let endpoint = customerProfiles["endpoint"] as? String
        else {
            throw ConnectError.configuration(
                "Missing notifications.amazon_connect_customer_profiles in \(resource).json",
                "Ensure your backend has notifications configured and \(resource).json is up to date."
            )
        }

        try Self.validateEndpoint(endpoint)

        self.region = region
        self.endpoint = endpoint
    }

    /// Validates that the endpoint is a well-formed URL using the `https` scheme.
    ///
    /// Called when loading configuration from `amplify_outputs.json`, and again
    /// by the client before every request, so manually constructed
    /// configurations are enforced too.
    ///
    /// - Throws: ``ConnectError/configuration(_:_:_:)`` for malformed or non-https endpoints.
    static func validateEndpoint(_ endpoint: String) throws {
        guard let url = URL(string: endpoint),
              let scheme = url.scheme,
              url.host != nil
        else {
            throw ConnectError.configuration(
                "Invalid endpoint URL: \(endpoint)",
                "Provide a valid https endpoint URL."
            )
        }

        guard scheme.lowercased() == "https" else {
            throw ConnectError.configuration(
                "Endpoint must use the https scheme, got \"\(scheme)\"",
                "Use an https endpoint URL."
            )
        }
    }
}
