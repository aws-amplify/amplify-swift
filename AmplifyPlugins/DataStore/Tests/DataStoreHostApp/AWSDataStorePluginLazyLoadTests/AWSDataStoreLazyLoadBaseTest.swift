//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine
import AWSDataStorePlugin
import AWSPluginsCore
import AWSAPIPlugin

@testable import Amplify

class AWSDataStoreLazyLoadBaseTest: XCTestCase {
    var requests: Set<AnyCancellable> = []
    
    var amplifyConfig: AmplifyConfiguration!
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    override func tearDown() async throws {
        try await clearDataStore()
        requests = []
        await Amplify.reset()
    }
    
    func setupConfig() {
        let basePath = "testconfiguration"
        let baseFileName = "AWSDataStoreCategoryPluginLazyLoadIntegrationTests"
        let configFile = "\(basePath)/\(baseFileName)-amplifyconfiguration"
        
        do {
            amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: configFile)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    func apiEndpointName() throws -> String {
        guard let apiPlugin = amplifyConfig.api?.plugins["awsAPIPlugin"],
              case .object(let value) = apiPlugin else {
            throw APIError.invalidConfiguration("API endpoint not found.", "Check the provided configuration")
        }
        return value.keys.first!
    }
    
    /// Setup DataStore with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration,
               logLevel: LogLevel = .verbose,
               eagerLoad: Bool = true) async {
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            
            try Amplify.add(plugin: AWSDataStorePlugin(
                modelRegistration: models,
                configuration: .custom(
                    loadingStrategy: eagerLoad ? .eagerLoad : .lazyLoad)))
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }
}
