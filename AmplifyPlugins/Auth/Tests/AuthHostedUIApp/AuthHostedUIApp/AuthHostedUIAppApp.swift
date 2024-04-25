//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

@main
struct AuthHostedUIAppApp: App {

    let amplifyConfigurationFile = "testconfiguration/AWSCognitoAuthPluginHostedUIIntegrationTests-amplifyconfiguration"
    let amplifyOutputsFile = "testconfiguration/AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs"
    var amplifyConfiguration: AmplifyConfiguration!

    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            if useGen2Configuration {
                let data = try ConfigurationHelper.retrieve(forResource: amplifyOutputsFile)
                try Amplify.configure(with: .data(data))
            } else {
                let configuration = retreiveConfiguration()
                try Amplify.configure(configuration)
            }

            print("Amplify configured with auth plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
    }
    
    func retreiveConfiguration() -> AmplifyConfiguration {
        do {
            return try ConfigurationHelper.retrieveAmplifyConfiguration(
                forResource: amplifyConfigurationFile)
        } catch {
            print(error)
        }
        return ConfigurationHelper.retrieveLocalConfig()
    }
}
