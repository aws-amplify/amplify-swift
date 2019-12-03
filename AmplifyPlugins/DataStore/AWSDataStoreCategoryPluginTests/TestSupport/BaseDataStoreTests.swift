//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class BaseDataStoreTests: XCTestCase {

    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        sleep(2)
        Amplify.reset()
        Amplify.Logging.logLevel = .warn

        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(models: StorageEngine.systemModels)

            let syncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter)
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          syncEngine: syncEngine,
                                          isSyncEnabled: true)
        } catch {
            XCTFail(String(describing: error))
            return
        }

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                         storageEngine: storageEngine,
                                                         dataStorePublisher: dataStorePublisher)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        // Since these tests use syncable models, we have to set up an API category also
        let apiConfig = APICategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let apiPlugin = MockAPICategoryPlugin()

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    // MARK: - Utilities

    func populateData<M: Model>(_ models: [M]) {
        let semaphore = DispatchSemaphore(value: 0)

        func save(model: M, index: Int) {
            storageAdapter.save(model) {
                switch $0 {
                case .success:
                    let nextIndex = index + 1
                    if nextIndex < models.endIndex {
                        save(model: models[nextIndex], index: nextIndex)
                    } else {
                        semaphore.signal()
                    }
                case .failure(let error):
                    XCTFail(error.errorDescription)
                    semaphore.signal()
                }
            }
        }

        if let model = models.first {
            save(model: model, index: 0)
            semaphore.wait()
        } else {
            semaphore.signal()
        }

    }
}
