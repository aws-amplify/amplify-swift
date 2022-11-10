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
    var amplifyConfiguration: AmplifyConfiguration!

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    init() {
        do {
            let configuration = retreiveConfiguration()
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure(configuration)
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
