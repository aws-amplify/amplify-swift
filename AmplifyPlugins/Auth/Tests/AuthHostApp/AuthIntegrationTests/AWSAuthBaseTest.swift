//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AWSAuthBaseTest: XCTestCase {

    let networkTimeout = TimeInterval(5)

    var defaultTestEmail = "xx"
    var defaultTestPassword = "xx"

    let amplifyConfigurationFile = "testconfiguration/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration"
    let credentialsFile = "testconfiguration/AWSCognitoAuthPluginIntegrationTests-credentials"

    var amplifyConfiguration: AmplifyConfiguration!

    func initializeAmplify() {
        do {
            let credentialsConfiguration = try TestConfigHelper.retrieveCredentials(forResource: credentialsFile)
            defaultTestEmail = credentialsConfiguration["test_email_1"] ?? defaultTestEmail
            defaultTestPassword = credentialsConfiguration["password"] ?? defaultTestPassword
            let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: amplifyConfigurationFile)
            amplifyConfiguration = configuration
            let authPlugin = AWSCognitoAuthPlugin()
            try Amplify.add(plugin: authPlugin)
            try Amplify.configure(configuration)
            print("Amplify configured with auth plugin")
        } catch {
            print(error)
            initializeWithLocalResources()
        }
    }

    func initializeWithLocalResources() {
        let region = JSONValue(stringLiteral: "xx")
        let userPoolID = JSONValue(stringLiteral: "xx")
        let userPooldAppClientID = JSONValue(stringLiteral: "xx")
        let userPooldAppClientSecret = JSONValue(stringLiteral: "xx")

        let identityPoolID = JSONValue(stringLiteral: "xx")
        do {
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
            let configuration = AmplifyConfiguration(auth: authConfiguration)
            let authPlugin = AWSCognitoAuthPlugin()
            try Amplify.add(plugin: authPlugin)
            try Amplify.configure(configuration)
        } catch {
            print(error)
            XCTFail("Amplify configuration failed")
        }
    }
}

class TestConfigHelper {

    static func retrieveAmplifyConfiguration(forResource: String) throws -> AmplifyConfiguration {

        let data = try retrieve(forResource: forResource)
        return try AmplifyConfiguration.decodeAmplifyConfiguration(from: data)
    }

    static func retrieveCredentials(forResource: String) throws -> [String: String] {
        let data = try retrieve(forResource: forResource)

        let jsonOptional = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
        guard let json = jsonOptional else {
            throw TestConfigError.jsonError("Could not deserialize `\(forResource)` into JSON object")
        }

        return json
    }

    private static func retrieve(forResource: String) throws -> Data {
        guard let path = Bundle(for: self).path(forResource: forResource, ofType: "json") else {
            throw TestConfigError.bundlePathError("Could not retrieve configuration file: \(forResource)")
        }

        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }
}

enum TestConfigError: Error {

    case jsonError(String)

    case bundlePathError(String)
}
