//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Amplify
import AWSDataStorePlugin

@main
struct DataStoreDocsAppApp: App {
    static let amplifyConfiguration = "testconfiguration/DataStoreDocsApp-amplifyconfiguration"

    final public class AmplifyModels: AmplifyModelRegistration {
      public let version: String = "c675a57695b11cb0cef0830b707ee171"
      
      public func registerModels(registry: ModelRegistry.Type) {
      }
    }
    init() {
        do {
            Amplify.Logging.logLevel = .verbose
            let config = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfiguration)
            // AmplifyModels is generated in the previous step
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(config)
            print("Amplify configured with DataStore plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
