//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.SwiftLogger
@_spi(FileBasedConfig) import AWSSDKCommon
import ClientRuntime

@_spi(DefaultRegionResolver)
public struct DefaultRegionResolver: RegionResolver {
    public let providers: [RegionProvider]
    let logger: SwiftLogger

    public init(fileBasedConfigurationProvider: @escaping FileBasedConfigurationProviding) throws {
        self.providers = [
            EnvironmentRegionProvider(),
            ProfileRegionProvider(fileBasedConfigurationProvider: fileBasedConfigurationProvider),
            try IMDSRegionProvider()
        ]
        self.logger = SwiftLogger(label: "DefaultRegionProvider")
    }

    public func getRegion() async -> String? {
        for provider in providers {
            logger.debug("Attempting to resolve region with: \(String(describing: type(of: provider)))")
            do {
                if let region = try await provider.getRegion() {
                    logger.debug("Resolved region with: \(String(describing: type(of: provider)))")
                    return region
                }
            } catch {
                let logMessage = [
                    "Failed to resolve region with: \(String(describing: type(of: provider)))",
                    "Error: \(error.localizedDescription)"
                ].joined(separator: "\n")
                logger.debug(logMessage)
            }
        }
        logger.debug("Unable to resolve region")
        return nil
    }
}

public struct StaticRegionResolver: RegionResolver {
    public let providers: [RegionProvider] = []
    private let region: String
    public init(_ region: String) {
        self.region = region
    }

    public func getRegion() async -> String? {
        return region
    }
}
