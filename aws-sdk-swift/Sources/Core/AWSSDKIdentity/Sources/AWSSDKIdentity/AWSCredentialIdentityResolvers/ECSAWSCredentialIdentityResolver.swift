//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CredentialsProvider
import ClientRuntime
import class Foundation.ProcessInfo
import enum Smithy.ClientError
import enum SmithyHTTPAPI.HTTPClientError
import protocol SmithyIdentity.AWSCredentialIdentityResolvedByCRT
import struct Foundation.URL
import struct Foundation.URLComponents

/// A credential identity resolver that sources credentials from ECS container metadata
public struct ECSAWSCredentialIdentityResolver: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider
    public let resolvedHost: String
    public let resolvedPathAndQuery: String
    public let resolvedAuthorizationToken: String?

    /// Creates a credential identity resolver that resolves credentials from ECS container metadata.
    /// ECS creds provider can be used to access creds via either relative uri to a fixed endpoint http://169.254.170.2,
    /// or via a full uri specified by environment variables:
    /// - AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
    /// - AWS_CONTAINER_CREDENTIALS_FULL_URI
    /// - AWS_CONTAINER_AUTHORIZATION_TOKEN
    ///
    /// If both relative uri and absolute uri are set, relative uri has higher priority.
    /// Token is used in auth header but only for absolute uri.
    /// - Throws: CommonRuntimeError.crtError or InitializationError.missingURIs
    public init(
        relativeURI: String? = nil,
        absoluteURI: String? = nil,
        authorizationToken: String? = nil
    ) throws {
        let env = ProcessEnvironment()

        let resolvedRelativeURI = relativeURI ?? env.environmentVariable(key: "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
        let resolvedAbsoluteURI = absoluteURI ?? env.environmentVariable(key: "AWS_CONTAINER_CREDENTIALS_FULL_URI")

        guard resolvedRelativeURI != nil || isValidAbsoluteURI(resolvedAbsoluteURI) else {
            throw ClientError.dataNotFound(
                "Please configure either the relative or absolute URI environment variable!"
            )
        }

        let defaultHost = "169.254.170.2"
        var host = defaultHost
        var pathAndQuery = resolvedRelativeURI ?? ""
        var resolvedAuthToken: String?

        if let relative = resolvedRelativeURI {
            pathAndQuery = relative
        } else if let absolute = resolvedAbsoluteURI, let absoluteURL = URL(string: absolute) {
            let (absoluteHost, absolutePathAndQuery) = try retrieveHostPathAndQuery(from: absoluteURL)
            host = absoluteHost
            pathAndQuery = absolutePathAndQuery
            resolvedAuthToken = try resolveToken(authorizationToken, env)
        } else {
            throw HTTPClientError.pathCreationFailed(
                "Failed to retrieve either relative or absolute URI! URI may be malformed."
            )
        }

        self.resolvedHost = host
        self.resolvedPathAndQuery = pathAndQuery
        self.resolvedAuthorizationToken = resolvedAuthToken
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(source: .ecs(
            bootstrap: SDKDefaultIO.shared.clientBootstrap,
            authToken: resolvedAuthToken,
            pathAndQuery: pathAndQuery,
            host: host
        ))
    }
}

private func retrieveHostPathAndQuery(from url: URL) throws -> (String, String) {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        let message = "Absolute URI is malformed! Could not instantiate URLComponents from URL."
        throw HTTPClientError.pathCreationFailed(message)
    }
    guard let hostComponent = components.host else {
        throw HTTPClientError.pathCreationFailed("Absolute URI is malformed! Could not retrieve host from URL.")
    }
    components.scheme = nil
    components.host = nil
    guard let pathQueryFragment = components.url else {
        throw HTTPClientError.pathCreationFailed("Could not retrieve path from URL!")
    }
    return (hostComponent, pathQueryFragment.absoluteString)
}

private func isValidAbsoluteURI(_ uri: String?) -> Bool {
    guard let validUri = uri, URL(string: validUri)?.host != nil else {
        return false
    }
    return true
}

private func resolveToken(_ authorizationToken: String?, _ env: ProcessEnvironment) throws -> String? {
    // Initialize token variable
    var tokenFromFile: String?
    if let tokenPath = env.environmentVariable(
        key: "AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE"
    ) {
        do {
            // Load the token from the file
            let tokenFilePath = URL(fileURLWithPath: tokenPath)
            tokenFromFile = try String(contentsOf: tokenFilePath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw ClientError.dataNotFound("Error reading the token file: \(error)")
        }
    }

    // AWS_CONTAINER_AUTHORIZATION_TOKEN should only be used if AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE is not set
    return authorizationToken ?? tokenFromFile ?? env.environmentVariable(key: "AWS_CONTAINER_AUTHORIZATION_TOKEN")
}

private struct ProcessEnvironment {
    public init() {}

    public func environmentVariable(key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
}
