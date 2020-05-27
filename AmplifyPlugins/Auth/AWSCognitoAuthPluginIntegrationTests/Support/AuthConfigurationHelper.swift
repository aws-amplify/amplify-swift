//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class AuthConfigurationHelper {

    static func amplifyConfiguration(with fileName: String = "amplifyconfiguration") throws -> AmplifyConfiguration {

        let testBundle = Bundle(for: self)
        guard let configurationFile = testBundle.url(forResource: fileName, withExtension: "json") else {
            throw AuthTestError.invalidData
        }
        guard let configurationData = try? Data(contentsOf: configurationFile) else {
           throw AuthTestError.invalidData
        }

        guard let configuration = try? JSONDecoder().decode(AmplifyConfiguration.self, from: configurationData) else {
            throw AuthTestError.parseError
        }
        return configuration
    }
}

enum AuthTestError: Error {
    case parseError
    case invalidData
}
