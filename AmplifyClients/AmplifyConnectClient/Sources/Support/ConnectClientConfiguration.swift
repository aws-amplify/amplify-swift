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
    /// Reads the `notifications.amazon_connect` key.
    ///
    /// - Parameters:
    ///   - resource: The resource file name **without** an extension — the `.json`
    ///     extension is implied. Defaults to `"amplify_outputs"`.
    ///   - bundle: The bundle containing the resource. Defaults to `.main`.
    /// - Throws: ``ConnectError/configuration(_:_:_:)`` if `resource` includes a file
    ///   extension, or if the file cannot be read, parsed, or is missing required keys.
    public init(from resource: String = "amplify_outputs", bundle: Bundle = .main) throws {
        // A resource name carrying an extension would silently fail to resolve
        // (Bundle would look for "amplify_outputs.json.json"), so reject it with
        // an actionable message rather than a confusing not-found error.
        let resourceURL = URL(fileURLWithPath: resource)
        guard resourceURL.pathExtension.isEmpty else {
            throw ConnectError.configuration(
                "Resource name \"\(resource)\" must not include a file extension",
                "Pass the file name without an extension, e.g. "
                    + "\"\(resourceURL.deletingPathExtension().lastPathComponent)\"."
            )
        }

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

        // Each level is unwrapped separately so the error names the value that is
        // actually missing, rather than attributing every failure to one key.
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ConnectError.configuration(
                "\(resource).json is not a valid JSON object",
                "Regenerate \(resource).json from your Amplify backend."
            )
        }

        guard let notifications = json["notifications"] as? [String: Any] else {
            throw ConnectError.configuration(
                "Missing \"notifications\" in \(resource).json",
                "Ensure your backend defines notifications and \(resource).json is up to date."
            )
        }

        guard let amazonConnect = notifications["amazon_connect"] as? [String: Any] else {
            throw ConnectError.configuration(
                "Missing \"notifications.amazon_connect\" in \(resource).json",
                "Ensure your backend configures Amazon Connect and \(resource).json is up to date."
            )
        }

        guard let region = amazonConnect["aws_region"] as? String else {
            throw ConnectError.configuration(
                "Missing \"notifications.amazon_connect.aws_region\" in \(resource).json",
                "Regenerate \(resource).json from your Amplify backend."
            )
        }

        guard let endpoint = amazonConnect["endpoint"] as? String else {
            throw ConnectError.configuration(
                "Missing \"notifications.amazon_connect.endpoint\" in \(resource).json",
                "Regenerate \(resource).json from your Amplify backend."
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
