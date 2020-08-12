//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class AuthConfigurationHelper {

    static func amplifyConfiguration(with fileName: String = "amplifyconfiguration") throws -> AmplifyConfiguration {
        guard let configurationData = try? getConfigurationData(with: fileName) else {
            throw AuthTestError.invalidData
        }
        guard let configuration = try? JSONDecoder().decode(AmplifyConfiguration.self, from: configurationData) else {
            throw AuthTestError.parseError
        }
        return configuration
    }

    static func credentialsConfiguration(with fileName: String = "credentials") throws -> JSONValue {
        guard let configurationData = try? getConfigurationData(with: fileName) else {
            throw AuthTestError.invalidData
        }

        guard let configuration = try? JSONDecoder().decode(JSONValue.self, from: configurationData) else {
            throw AuthTestError.parseError
        }
        return configuration
    }

    static func getConfigurationData(with fileName: String) throws -> Data {
        let testBundle = Bundle(for: self)
        guard let configurationFile = testBundle.url(forResource: fileName, withExtension: "json") else {
            throw AuthTestError.invalidData
        }
        guard let configurationData = try? Data(contentsOf: configurationFile) else {
           throw AuthTestError.invalidData
        }
        return configurationData
    }
}

enum AuthTestError: Error {
    case parseError
    case invalidData
}
