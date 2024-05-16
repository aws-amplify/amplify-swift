//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(InternalAmplifyConfiguration) @testable import Amplify
import AWSCognitoAuthPlugin

class AWSAuthBaseTest: XCTestCase {

    let networkTimeout = TimeInterval(5)

    var defaultTestEmail = "test-\(UUID().uuidString)@amazon.com"
    var defaultTestPassword = UUID().uuidString

    var randomEmail: String {
        "test-\(UUID().uuidString)@amazon.com"
    }

    var randomPhoneNumber: String {
        "+1" + (1...10)
            .map { _ in String(Int.random(in: 0...9)) }
            .joined()
    }

    var amplifyConfigurationFile = "testconfiguration/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration"
    var amplifyOutputsFile =
        "testconfiguration/AWSCognitoAuthPluginIntegrationTests-amplify_outputs"
    let credentialsFile = "testconfiguration/AWSCognitoAuthPluginIntegrationTests-credentials"

    var amplifyConfiguration: AmplifyConfiguration!
    var amplifyOutputs: AmplifyOutputsData!

    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2")
    }

    override func setUp() async throws {
        try await super.setUp()
        initializeAmplify()
        _ = await Amplify.Auth.signOut()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
    }

    func initializeAmplify() {
        do {
            let credentialsConfiguration = (try? TestConfigHelper.retrieveCredentials(forResource: credentialsFile)) ?? [:]
            defaultTestEmail = credentialsConfiguration["test_email_1"] ?? defaultTestEmail
            defaultTestPassword = credentialsConfiguration["password"] ?? defaultTestPassword
            let authPlugin = AWSCognitoAuthPlugin()
            try Amplify.add(plugin: authPlugin)

            if useGen2Configuration {
                let data = try TestConfigHelper.retrieve(forResource: amplifyOutputsFile)
                try Amplify.configure(with: .data(data))
            } else {
                let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(
                    forResource: amplifyConfigurationFile)
                amplifyConfiguration = configuration
                try Amplify.configure(amplifyConfiguration)
            }
            Amplify.Logging.logLevel = .verbose
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

    static func retrieve(forResource: String) throws -> Data {
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
