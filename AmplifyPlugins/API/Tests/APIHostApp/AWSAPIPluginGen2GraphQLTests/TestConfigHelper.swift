//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAmplifyConfiguration) @testable import Amplify

class TestConfigHelper {

    static func retrieveAmplifyOutputsData(forResource: String) throws -> AmplifyOutputsData {
        let data = try retrieve(forResource: forResource)
        return try AmplifyOutputsData.decodeAmplifyOutputsData(from: data)
    }

    static func retrieve(forResource: String) throws -> Data {
        guard let path = Bundle(for: self).path(forResource: forResource, ofType: "json") else {
            throw "Could not retrieve configuration file: \(forResource)"
        }

        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }
}

extension String {
    var withUUID: String {
        "\(self)-\(UUID().uuidString)"
    }
}
