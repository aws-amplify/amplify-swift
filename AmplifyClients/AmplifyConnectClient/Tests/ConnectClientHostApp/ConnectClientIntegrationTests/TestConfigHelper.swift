//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class TestConfigHelper {

    static func retrieve(forResource: String) throws -> Data {
        guard let path = Bundle(for: self).path(forResource: forResource, ofType: "json") else {
            throw TestConfigError.bundlePathError("Could not retrieve configuration file: \(forResource)")
        }

        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }

    static func retrieveCredentials(forResource: String) throws -> [String: String] {
        let data = try retrieve(forResource: forResource)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            throw TestConfigError.jsonError("Could not deserialize `\(forResource)` into JSON object")
        }
        return json
    }
}

enum TestConfigError: Error {
    case bundlePathError(String)
    case jsonError(String)
}
