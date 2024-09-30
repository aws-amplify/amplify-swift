//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentity.BearerTokenIdentityResolver
import struct SmithyIdentity.BearerTokenIdentity
import class Foundation.FileManager
import struct Foundation.URL
import struct Foundation.Data
import class Foundation.JSONDecoder
import struct Smithy.Attributes
import AwsCommonRuntimeKit
import enum Smithy.ClientError
import func Foundation.NSHomeDirectory
@_spi(FileBasedConfig) import AWSSDKCommon

/// The bearer token identity resolver that resolves token identity using the config file & the cached SSO token.
/// This resolver does not handle creation of the SSO token; it must be created by the user beforehand (e.g., using AWS CLI, etc.).
public struct SSOBearerTokenIdentityResolver: BearerTokenIdentityResolver {
    private let profileName: String?
    private let configFilePath: String?
    private let fileBasedConfig: CRTFileBasedConfiguration

    /// - Parameters:
    ///    - profileName: The profile name to use. If not provided it will be resolved internally via the `AWS_PROFILE` environment variable or defaulted to `default` if not configured.
    ///    - configFilePath: The path to the configuration file to use. If not provided it will be resolved internally via the `AWS_CONFIG_FILE` environment variable or defaulted  to `~/.aws/config` if not configured.
    public init(
        profileName: String? = nil,
        configFilePath: String? = nil
    ) throws {
        self.profileName = profileName
        self.configFilePath = configFilePath
        self.fileBasedConfig = try CRTFileBasedConfiguration(configFilePath: configFilePath)
    }

    public func getIdentity(
        identityProperties: Smithy.Attributes?
    ) async throws -> SmithyIdentity.BearerTokenIdentity {
        return BearerTokenIdentity(token: try getCachedTokenString())
    }

    private func getCachedTokenString() throws -> String {
        // Get sso session name connected to given profile name; or to default profile name, if no profile name was given.
        let ssoSessionName = fileBasedConfig.getSection(
            name: profileName ?? FileBasedConfiguration.defaultProfileName, sectionType: .profile
        )?.getProperty(name: "sso_session")?.value
        // Get SHA1 hash of the name
        guard let ssoSessionName else {
            throw ClientError.dataNotFound("Failed to retrieve name of sso-session name in the config file.")
        }
        let tokenFileName = try ssoSessionName.data(using: .utf8)!.computeSHA1().encodeToHexString() + ".json"
        // Get the access token file URL
        let homeDir = getHomeDirectoryURL()
        let relativePath = ".aws/sso/cache/\(tokenFileName)"
        let tokenFileURL = homeDir.appendingPathComponent(relativePath)
        // Load & return the access token
        return try loadTokenFile(fileURL: tokenFileURL)
    }

    private func getHomeDirectoryURL() -> URL {
        #if os(macOS)
        // On macOS, use homeDirectoryForCurrentUser
        return FileManager.default.homeDirectoryForCurrentUser
        #else
        // On iOS, tvOS, and watchOS, use NSHomeDirectory()
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        #endif
    }
}

private struct TokenFile: Decodable {
    var startUrl: String
    var region: String
    var accessToken: String
    var expiresAt: String
    var clientId: String
    var clientSecret: String
    var registrationExpiresAt: String
    var refreshToken: String
}

public func loadTokenFile(fileURL: URL) throws -> String {
    do {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let jsonData = try decoder.decode(TokenFile.self, from: data)
        return jsonData.accessToken
    } catch {
        throw ClientError.dataNotFound("Failed to load token file.")
    }
}
