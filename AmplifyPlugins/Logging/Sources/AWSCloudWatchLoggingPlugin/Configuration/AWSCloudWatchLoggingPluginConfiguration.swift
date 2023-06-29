//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSCloudWatchLoggingPluginConfiguration: Codable {
    public init(
        logGroupName: String,
        region: String,
        enable: Bool = true,
        localStoreMaxSizeInMB: Int = 5,
        flushIntervalInSeconds: Int = 60,
        defaultRemoteConfiguration: DefaultRemoteConfiguration? = nil,
        loggingConstraints: LoggingConstraints = LoggingConstraints()
     ) {
         self.logGroupName = logGroupName
         self.region = region
         self.enable = enable
         self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
         self.flushIntervalInSeconds = flushIntervalInSeconds
         self.defaultRemoteConfiguration = defaultRemoteConfiguration
         self.loggingConstraints = loggingConstraints
    }

   public let enable: Bool
   public let logGroupName: String
   public let region: String
   public let localStoreMaxSizeInMB: Int
   public let flushIntervalInSeconds: Int
   public let defaultRemoteConfiguration: DefaultRemoteConfiguration?
   public let loggingConstraints: LoggingConstraints
}

import Amplify
import AWSPluginsCore

extension AWSCloudWatchLoggingPluginConfiguration {
    init(bundle: Bundle) throws {
        guard let path = bundle.path(forResource: "amplifyconfiguration_logging", ofType: "json") else {
            throw LoggingError.configuration(
                """
                Could not load default `amplifyconfiguration_logging.json` file
                """,
                """
                Expected to find the file, `amplifyconfiguration_logging.json` in the app bundle at `\(bundle.bundlePath)`, but
                it was not present. Either add amplifyconfiguration_logging.json to your app's "Copy Bundle Resources" build phase.
                """
            )
        }

        let url = URL(fileURLWithPath: path)

        self = try AWSCloudWatchLoggingPluginConfiguration.loadConfiguration(from: url)
    }

    static func loadConfiguration(from url: URL) throws -> AWSCloudWatchLoggingPluginConfiguration {
        let fileData: Data
        do {
            fileData = try Data(contentsOf: url)
        } catch {
            throw LoggingError.configuration(
                """
                Could not extract UTF-8 data from `\(url.path)`
                """,

                """
                Could not load data from the file at `\(url.path)`. Inspect the file to ensure it is present.
                The system reported the following error:
                \(error.localizedDescription)
                """,
                error
            )
        }

        return try decodeConfiguration(from: fileData)
    }

    static func decodeConfiguration(from data: Data) throws -> AWSCloudWatchLoggingPluginConfiguration {
        let jsonDecoder = JSONDecoder()

        do {
            let configuration = try jsonDecoder.decode(AmplifyConfigurationLogging.self, from: data)
            return configuration.awsCloudWatchLoggingPlugin
        } catch {
            throw LoggingError.configuration(
                """
                Could not decode `amplifyconfiguration_logging.json` into a valid AWSCloudWatchLoggingPluginConfiguration object
                """,

                """
                `amplifyconfiguration_logging.json` was found, but could not be converted to an AmplifyConfiguration object
                using the default JSONDecoder. The system reported the following error:
                \(error.localizedDescription)
                """,
                error
            )
        }
    }
}

