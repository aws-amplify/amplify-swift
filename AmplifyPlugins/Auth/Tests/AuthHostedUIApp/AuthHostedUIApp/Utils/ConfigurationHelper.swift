//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class ConfigurationHelper {

    static func retrieveAmplifyConfiguration(forResource: String) throws -> AmplifyConfiguration {

        let data = try retrieve(forResource: forResource)
        return try Self.decodeAmplifyConfiguration(from: data)
    }

    static func retrieveLocalConfig() -> AmplifyConfiguration {
        let region = JSONValue(stringLiteral: "xx")
        let userPoolID = JSONValue(stringLiteral: "xx")
        let userPooldAppClientID = JSONValue(stringLiteral: "xx")

        let identityPoolID = JSONValue(stringLiteral: "xx")
        let authConfiguration = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "UserAgent": "aws-amplify/cli",
                "Version": "0.1.0",
                "IdentityManager": [
                    "Default": []
                ],
                "CredentialsProvider": [
                    "CognitoIdentity": [
                        "Default": [
                            "PoolId": identityPoolID,
                            "Region": region
                        ]
                    ]
                ],
                "CognitoUserPool": [
                    "Default": [
                        "PoolId": userPoolID,
                        "AppClientId": userPooldAppClientID,
                        "Region": region
                    ]
                ]]]
        )
        return AmplifyConfiguration(auth: authConfiguration)
    }

    private static func retrieve(forResource: String) throws -> Data {
        guard let path = Bundle(for: self).path(forResource: forResource, ofType: "json") else {
            throw ConfigurationError.bundlePathError(
                "Could not retrieve configuration file: \(forResource)")
        }

        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }

    private static func decodeAmplifyConfiguration(from data: Data) throws -> AmplifyConfiguration {
        let jsonDecoder = JSONDecoder()

        do {
            let configuration = try jsonDecoder.decode(AmplifyConfiguration.self, from: data)
            return configuration
        } catch {
            throw ConfigurationError.jsonError(
                """
                Could not decode `amplifyconfiguration.json` into a valid AmplifyConfiguration object
                \(error.localizedDescription)
                """
            )
        }
    }
}


enum ConfigurationError: Error {

    case jsonError(String)

    case bundlePathError(String)
}
