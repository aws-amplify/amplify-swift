//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

class TestConfigHelper {

    static func retrieveAmplifyConfiguration(forResource: String) throws -> AmplifyConfiguration {
        let data = try retrieve(forResource: forResource)
        return try AmplifyConfiguration.decodeAmplifyConfiguration(from: data)
    }

    static func retrieveCredentials(forResource: String) throws -> [String: String] {
        let data = try retrieve(forResource: forResource)
        let jsonOptional = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
        guard let json = jsonOptional else {
            throw "Could not deserialize `\(forResource)` into JSON object"
        }
        return json
    }

    static func retrieve(forResource: String) throws -> Data {
        let bundle = Bundle(for: self)
        guard let path = bundle.path(forResource: forResource, ofType: "json") else {
            let bundlePath = bundle.bundlePath
            let resourcePath = bundle.resourcePath ?? "nil"
            let allFiles = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath)) ?? []
            let testconfigFiles = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath + "/testconfiguration")) ?? ["<testconfiguration dir not found>"]
            throw """
                Could not retrieve configuration file: \(forResource)
                Bundle path: \(bundlePath)
                Resource path: \(resourcePath)
                Top-level items (\(allFiles.count)): \(allFiles.sorted().joined(separator: ", "))
                testconfiguration/ contents: \(testconfigFiles.sorted().joined(separator: ", "))
                """
        }
        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }
}

extension String: @retroactive Error {}
