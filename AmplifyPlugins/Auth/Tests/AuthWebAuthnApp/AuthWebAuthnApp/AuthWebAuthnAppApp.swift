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

    private let amplifyOutputsFilePath = "testconfiguration/AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs"

    init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())

            let data = try TestConfigHelper.retrieve(forResource: amplifyOutputsFilePath)
            try Amplify.configure(with: .data(data))
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

}
