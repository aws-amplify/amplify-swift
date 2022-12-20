//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine
@testable import AWSDataStorePlugin
import AWSPluginsCore
import AWSAPIPlugin

@testable import Amplify

class AWSDataStoreLazyLoadBaseTest: XCTestCase {
    var requests: Set<AnyCancellable> = []
    
    var amplifyConfig: AmplifyConfiguration!
    
    var apiOnly: Bool = false
    var clearOnTearDown: Bool = false
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    override func tearDown() async throws {
        if !apiOnly && clearOnTearDown {
            try await clearDataStore()
        }
        
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
               clearOnTearDown: Bool = true) async {
        self.clearOnTearDown = clearOnTearDown
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure(amplifyConfig)
            
            try await deleteMutationEvents()
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    func setUpDataStoreOnly(withModels models: AmplifyModelRegistration,
                            logLevel: LogLevel = .verbose,
                            clearOnTearDown: Bool = true) async {
        self.clearOnTearDown = clearOnTearDown
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
            try Amplify.configure(amplifyConfig)
            
            try await deleteMutationEvents()
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    func setupAPIOnly(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .verbose) async {
        apiOnly = true
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    func deleteMutationEvents() async throws {
        try await Amplify.DataStore.delete(MutationEvent.self, where: QueryPredicateConstant.all)
    }
    
    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }
    
    func startAndWaitForReady() async throws {
        let dataStoreReady = asyncExpectation(description: "DataStore `ready` event received")
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                if event.eventName == dataStoreEvents.ready {
                    Task {
                        await dataStoreReady.fulfill()
                    }
                }
            }
            .store(in: &requests)
        try await startDataStore()
        await waitForExpectations([dataStoreReady], timeout: 60)
    }
    
    func startDataStore() async throws {
        try await Amplify.DataStore.start()
    }
    
    func printDBPath() {
        let dbPath = DataStoreDebugger.dbFilePath
        print("DBPath: \(dbPath)")
    }
    
    func saveAndWaitForSync<M: Model>(_ model: M, assertVersion: Int = 1) async throws -> M {
        let modelSynced = asyncExpectation(description: "model was synced successfully")
        let mutationEvents = Amplify.DataStore.observe(M.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if mutationEvent.version == assertVersion && mutationEvent.modelId == model.identifier {
                    await modelSynced.fulfill()
                }
            }
        }
        let savedModel = try await Amplify.DataStore.save(model)
        await waitForExpectations([modelSynced], timeout: 100)
        return savedModel
    }
    
    func deleteAndWaitForSync<M: Model>(_ model: M) async throws {
        let modelSynced = asyncExpectation(description: "model was synced successfully")
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                if event.eventName == dataStoreEvents.outboxMutationProcessed,
                   let outboxMutationEvent = event.data as? OutboxMutationEvent,
                   outboxMutationEvent.modelName == model.modelName,
                   outboxMutationEvent.element.deleted == true {
                    Task { await modelSynced.fulfill() }
                    
                }
            }
            .store(in: &requests)
        try await Amplify.DataStore.delete(model)
        await waitForExpectations([modelSynced], timeout: 10)
    }
    
    enum AssertListState {
        case isNotLoaded(associatedId: String, associatedField: String)
        case isLoaded(count: Int)
    }
    
    func assertList<M: Model>(_ list: List<M>, state: AssertListState) {
        switch state {
        case .isNotLoaded(let expectedAssociatedId, let expectedAssociatedField):
            if case .notLoaded(let associatedIdentifiers, let associatedField) = list.listProvider.getState() {
                XCTAssertEqual(associatedIdentifiers.first, expectedAssociatedId)
                XCTAssertEqual(associatedField, expectedAssociatedField)
            } else {
                XCTFail("It should be not loaded with expected associatedId \(expectedAssociatedId) associatedField \(expectedAssociatedField)")
            }
        case .isLoaded(let count):
            if case .loaded(let loadedList) = list.listProvider.getState() {
                XCTAssertEqual(loadedList.count, count)
            } else {
                XCTFail("It should be loaded with expected count \(count)")
            }
        }
    }
    
    enum AssertLazyModelState<M: Model> {
        case notLoaded(identifiers: [LazyReferenceIdentifier]?)
        case loaded(model: M?)
    }
    
    func assertLazyReference<M: Model>(_ lazyModel: LazyReference<M>,
                                   state: AssertLazyModelState<M>) {
        switch state {
        case .notLoaded(let expectedIdentifiers):
            if case .notLoaded(let identifiers) = lazyModel.modelProvider.getState() {
                XCTAssertEqual(identifiers, expectedIdentifiers)
            } else {
                XCTFail("Should be not loaded with identifiers \(expectedIdentifiers)")
            }
        case .loaded(let expectedModel):
            if case .loaded(let model) = lazyModel.modelProvider.getState() {
                guard let expectedModel = expectedModel, let model = model else {
                    XCTAssertNil(model)
                    return
                }
                XCTAssertEqual(model.identifier, expectedModel.identifier)
            } else {
                XCTFail("Should be loaded with model \(String(describing: expectedModel))")
            }
        }
    }
    
    func assertModelExists<M: Model>(_ model: M) async throws {
        let modelExists = try await modelExists(model)
        XCTAssertTrue(modelExists)
    }
    
    func assertModelDoesNotExist<M: Model>(_ model: M) async throws {
        let modelExists = try await modelExists(model)
        XCTAssertFalse(modelExists)
    }
    
    func modelExists<M: Model>(_ model: M) async throws -> Bool {
        let identifierName = model.schema.primaryKey.sqlName
        let queryPredicate: QueryPredicate = field(identifierName).eq(model.identifier)
        
        let queriedModels = try await Amplify.DataStore.query(M.self,
                                                              where: queryPredicate)
        let metadataId = MutationSyncMetadata.identifier(modelName: model.modelName,
                                                         modelId: model.identifier)
        guard let metadata = try await Amplify.DataStore.query(MutationSyncMetadata.self,
                                                               byId: metadataId) else {
            XCTFail("Could not retrieve metadata for model \(model)")
            throw "Could not retrieve metadata for model \(model)"
        }
        
        return !(metadata.deleted && queriedModels.isEmpty)
    }
    
    func query<M: Model>(for model: M) async throws -> M {
        let identifierName = model.schema.primaryKey.sqlName
        let queryPredicate: QueryPredicate = field(identifierName).eq(model.identifier)
        
        let queriedModels = try await Amplify.DataStore.query(M.self,
                                                              where: queryPredicate)
        if queriedModels.count > 1 {
            XCTFail("Expected to find one model, found \(queriedModels.count). \(queriedModels)")
            throw "Expected to find one model, found \(queriedModels.count). \(queriedModels)"
        }
        if let queriedModel = queriedModels.first {
            return queriedModel
        } else {
            throw "Expected to find one model, found none"
        }
    }
}

struct DataStoreDebugger {
    
    static var dbFilePath: URL? { getAdapter()?.dbFilePath }
    
    static func getAdapter() -> SQLiteStorageEngineAdapter? {
        if let dataStorePlugin = tryGetPlugin(),
           let storageEngine = dataStorePlugin.storageEngine as? StorageEngine,
           let adapter = storageEngine.storageAdapter as? SQLiteStorageEngineAdapter {
            return adapter
        }
        
        print("Could not get `SQLiteStorageEngineAdapter` from DataStore")
        return nil
    }
    
    static func tryGetPlugin() -> AWSDataStorePlugin? {
        do {
            return try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as? AWSDataStorePlugin
        } catch {
            return nil
        }
    }
}

extension LazyReferenceIdentifier: Equatable {
    public static func == (lhs: LazyReferenceIdentifier, rhs: LazyReferenceIdentifier) -> Bool {
        lhs.name == rhs.name && lhs.value == rhs.value
    }
}
