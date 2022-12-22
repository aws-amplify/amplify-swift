//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import AWSClientRuntime
import Foundation

@_spi(InternalAWSPinpoint)
public struct AWSPinpointPluginConfiguration {
    static let appIdConfigKey = "appId"
    static let regionConfigKey = "region"

    public let appId: String
    public let region: String

    public init(_ configuration: JSONValue) throws {
        guard case let .object(configObject) = configuration else {
            throw PluginError.pluginConfigurationError(
                AWSPinpointErrorConstants.pinpointConfigurationExpected.errorDescription,
                AWSPinpointErrorConstants.pinpointConfigurationExpected.recoverySuggestion
            )
        }

        self.init(
            appId: try AWSPinpointPluginConfiguration.getAppId(configObject),
            region: try AWSPinpointPluginConfiguration.getRegion(configObject)
        )
    }

    private init(appId: String,
                 region: String) {
        self.appId = appId
        self.region = region
    }

    private static func getAppId(_ configuration: [String: JSONValue]) throws -> String {
        guard let appId = configuration[appIdConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AWSPinpointErrorConstants.missingAppId.errorDescription,
                AWSPinpointErrorConstants.missingAppId.recoverySuggestion
            )
        }

        guard case let .string(appIdValue) = appId else {
            throw PluginError.pluginConfigurationError(
                AWSPinpointErrorConstants.invalidAppId.errorDescription,
                AWSPinpointErrorConstants.invalidAppId.recoverySuggestion
            )
        }

        if appIdValue.isEmpty {
            throw PluginError.pluginConfigurationError(
                AWSPinpointErrorConstants.emptyAppId.errorDescription,
                AWSPinpointErrorConstants.emptyAppId.recoverySuggestion
            )
        }

        return appIdValue
    }

    private static func getRegion(_ configuration: [String: JSONValue]) throws -> String {
        guard let region = configuration[regionConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AWSPinpointErrorConstants.missingRegion.errorDescription,
                AWSPinpointErrorConstants.missingRegion.recoverySuggestion
            )
        }

        guard case let .string(regionValue) = region else {
            throw PluginError.pluginConfigurationError(
                AWSPinpointErrorConstants.invalidRegion.errorDescription,
                AWSPinpointErrorConstants.invalidRegion.recoverySuggestion
            )
        }

        if regionValue.isEmpty {
            throw PluginError.pluginConfigurationError(
                AWSPinpointErrorConstants.emptyRegion.errorDescription,
                AWSPinpointErrorConstants.emptyRegion.recoverySuggestion
            )
        }

        return regionValue
    }
}
