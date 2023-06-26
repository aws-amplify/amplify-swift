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

#if !os(watchOS)
@testable import DataStoreHostApp
#endif
@testable import Amplify

class AWSDataStoreLazyLoadBaseTest: XCTestCase {
    var amplifyConfig: AmplifyConfiguration!
    
    var apiOnly: Bool = false
    var modelsOnly: Bool = false
    var clearOnTearDown: Bool = false
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    override func tearDown() async throws {
        if !(apiOnly || modelsOnly) {
            try await clearDataStore()
        }
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
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
               clearOnTearDown: Bool = false) async {
        self.clearOnTearDown = clearOnTearDown
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models,
                                                       configuration: .custom(syncMaxRecords: 100)))
            try Amplify.add(plugin: AWSAPIPlugin(sessionFactory: AmplifyURLSessionFactory()))
            try Amplify.configure(amplifyConfig)
            
            try await Amplify.DataStore.start()
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    func setUpDataStoreOnly(withModels models: AmplifyModelRegistration,
                            logLevel: LogLevel = .verbose,
                            clearOnTearDown: Bool = false) async {
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
    
    func setUpModelRegistrationOnly(withModels models: AmplifyModelRegistration,
                                    logLevel: LogLevel = .verbose) {
        modelsOnly = true
        models.registerModels(registry: ModelRegistry.self)
    }
    
    func setupAPIOnly(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .verbose) async {
        apiOnly = true
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models, sessionFactory: AmplifyURLSessionFactory()))
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
        var requests: Set<AnyCancellable> = []
        let dataStoreReady = expectation(description: "DataStore `ready` event received")
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                if event.eventName == dataStoreEvents.ready {
                    dataStoreReady.fulfill()
                }
            }
            .store(in: &requests)
        try await startDataStore()
        await fulfillment(of: [dataStoreReady], timeout: 60)
    }
    
    func startDataStore() async throws {
        try await Amplify.DataStore.start()
    }
    
    func printDBPath() {
        let dbPath = DataStoreDebugger.dbFilePath
        print("DBPath: \(dbPath)")
    }
    
    @discardableResult
    func createAndWaitForSync<M: Model>(_ model: M) async throws -> M {
        var requests: Set<AnyCancellable> = []
        let modelSynced = expectation(description: "create model was synced successfully")
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelName == model.modelName }
            .filter { $0.modelId == model.identifier }
            .filter { $0.mutationType == MutationEvent.MutationType.create.rawValue }
            .sink { _ in
                modelSynced.fulfill()
            }
            .store(in: &requests)

        let savedModel = try await Amplify.DataStore.save(model)
        await fulfillment(of: [modelSynced], timeout: 100)
        return savedModel
    }
    
    @discardableResult
    func updateAndWaitForSync<M: Model>(_ model: M, assertVersion: Int? = nil) async throws -> M {
        var requests: Set<AnyCancellable> = []
        let modelSynced = expectation(description: "update model was synced successfully")
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelName == model.modelName }
            .filter { $0.modelId == model.identifier }
            .filter { $0.mutationType == MutationEvent.MutationType.update.rawValue }
            .compactMap(\.version)
            .filter { version in
                assertVersion.map({ $0 == version }) ?? true
            }
            .sink { _ in
                modelSynced.fulfill()
            }
            .store(in: &requests)

        let updatedModel = try await Amplify.DataStore.save(model)
        await fulfillment(of: [modelSynced], timeout: 100)
        return updatedModel
    }

    func deleteAndWaitForSync<M: Model>(_ model: M) async throws {
        var requests: Set<AnyCancellable> = []
        let modelSynced = expectation(description: "delete model was synced successfully")
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == dataStoreEvents.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelName == model.modelName }
            .filter { $0.modelId == model.identifier }
            .filter { $0.mutationType == MutationEvent.MutationType.delete.rawValue }
            .sink { _ in
                modelSynced.fulfill()
            }
            .store(in: &requests)
        try await Amplify.DataStore.delete(model)
        await fulfillment(of: [modelSynced], timeout: 10)
    }
    
    enum AssertListState {
        case isNotLoaded(associatedIds: [String], associatedFields: [String])
        case isLoaded(count: Int)
    }
    
    func assertList<M: Model>(_ list: List<M>, state: AssertListState) {
        switch state {
        case .isNotLoaded(let expectedAssociatedIds, let expectedAssociatedFields):
            if case .notLoaded(let associatedIdentifiers, let associatedFields) = list.listProvider.getState() {
                XCTAssertEqual(associatedIdentifiers, expectedAssociatedIds)
                XCTAssertEqual(associatedFields, expectedAssociatedFields)
            } else {
                XCTFail("It should be not loaded with expected associatedIds \(expectedAssociatedIds) associatedFields \(expectedAssociatedFields)")
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
