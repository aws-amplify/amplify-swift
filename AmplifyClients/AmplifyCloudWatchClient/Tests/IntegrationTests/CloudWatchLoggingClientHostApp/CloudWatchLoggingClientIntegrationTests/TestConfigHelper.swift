//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

class TestConfigHelper {

    static func retrieve(forResource: String) throws -> Data {
        guard let path = Bundle(for: self).path(forResource: forResource, ofType: "json") else {
            throw TestConfigError.bundlePathError("Could not retrieve configuration file: \(forResource)")
        }
        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }

    static func retrieveCloudWatchClientConfiguration(forResource: String) throws -> CloudWatchClientConfiguration {
        let data = try retrieve(forResource: forResource)
        return try JSONDecoder().decode(CloudWatchClientConfiguration.self, from: data)
    }
}

enum TestConfigError: Error {
    case jsonError(String)
    case bundlePathError(String)
}

struct CloudWatchClientConfiguration: Decodable {
    let cloudWatchClient: CloudWatchClientSettings

    struct CloudWatchClientSettings: Decodable {
        let enable: Bool
        let logGroupName: String
        let region: String
        let localStoreMaxSizeInMB: Int
        let flushIntervalInSeconds: Int
        let loggingConstraints: LoggingConstraintsConfig
    }

    struct LoggingConstraintsConfig: Decodable {
        let defaultLogLevel: String
    }
}
