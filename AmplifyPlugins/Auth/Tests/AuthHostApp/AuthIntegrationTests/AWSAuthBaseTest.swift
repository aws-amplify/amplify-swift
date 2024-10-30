//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(InternalAmplifyConfiguration) @testable import Amplify
import AWSCognitoAuthPlugin

fileprivate let internalTestDomain = "@amplify-swift-gamma.awsapps.com"

class AWSAuthBaseTest: XCTestCase {

    let networkTimeout = TimeInterval(5)

    var defaultTestEmail = "test-\(UUID().uuidString)\(internalTestDomain)"
    var defaultTestPassword = UUID().uuidString

    var randomEmail: String {
        "test-\(UUID().uuidString)\(internalTestDomain)"
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

    var onlyUseGen2Configuration = false

    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2") || onlyUseGen2Configuration
    }

    override func setUp() async throws {
        try await super.setUp()
        initializeAmplify()
        _ = await Amplify.Auth.signOut()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        subscription?.cancel()
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

    // Dictionary to store MFA codes with usernames as keys
    var mfaCodeDictionary: [String: String] = [:]
    var subscription: AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<[String: JSONValue]>>? = nil

    let document: String = """
    subscription OnCreateMfaInfo {
        onCreateMfaInfo {
          username
          code
          expirationTime
        }
    }
    """

    /// Function to create a subscription and store MFA codes in a dictionary
    func createMFASubscription() {
        subscription = Amplify.API.subscribe(request: .init(document: document, responseType: [String: JSONValue].self))

        // Create the subscription and listen for MFA code events
        Task {
            do {
                guard let subscription = subscription else { return }
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        print("Subscription connect state is \(subscriptionConnectionState)")
                    case .data(let result):
                        switch result {
                        case .success(let mfaCodeResult):
                            print("Successfully got MFA code from subscription: \(mfaCodeResult)")
                            if let eventUsername = mfaCodeResult["onCreateMfaInfo"]?.asObject?["username"]?.stringValue,
                               let code = mfaCodeResult["onCreateMfaInfo"]?.asObject?["code"]?.stringValue {
                                // Store the code in the dictionary for the given username
                                mfaCodeDictionary[eventUsername] = code
                            }
                        case .failure(let error):
                            print("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                print("Subscription terminated with error: \(error)")
            }
        }
    }

    /// Test that waits for the MFA code using XCTestExpectation
    func waitForMFACode(for username: String) async throws -> String? {
        let expectation = XCTestExpectation(description: "Wait for MFA code")
        expectation.expectedFulfillmentCount = 1
        
        let task = Task { () -> String? in
            var code: String?
            for _ in 0..<30 { // Poll for the code, max 30 times (once per second)
                if let mfaCode = mfaCodeDictionary[username] {
                    code = mfaCode
                    expectation.fulfill() // Fulfill the expectation when the value is found
                    break
                }
                try await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 second
            }
            return code
        }

        // Wait for expectation or timeout after 30 seconds
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: 30)

        if result == .timedOut {
            // Task cancels if timed out
            task.cancel()
            subscription?.cancel()
            return nil
        }

        subscription?.cancel()
        return try await task.value
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
