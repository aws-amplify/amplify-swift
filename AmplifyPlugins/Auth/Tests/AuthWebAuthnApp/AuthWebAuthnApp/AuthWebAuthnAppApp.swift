//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoAuthPlugin
import SwiftUI

@main
struct AuthWebAuthnAppApp: App {
    private let amplifyConfigurationFilePath = "testconfiguration/AWSCognitoPluginPasswordlessIntegrationTests-amplifyconfiguration"
    private let amplifyOutputsFilePath = "testconfiguration/AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs"

    init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())

            if useGen2Configuration {
                let data = try TestConfigHelper.retrieve(forResource: amplifyOutputsFilePath)
                try Amplify.configure(with: .data(data))
            } else {
                let config = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFilePath)
                try Amplify.configure(config)
            }
            print("Amplify configured!")
        } catch {
            print("Failed to init Amplify", error)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2")
    }
}
