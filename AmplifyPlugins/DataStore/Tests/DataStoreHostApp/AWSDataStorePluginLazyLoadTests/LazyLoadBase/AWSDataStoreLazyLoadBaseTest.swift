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
        await waitForExpectations([modelSynced], timeout: 10)
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
            if case .notLoaded(let associatedId, let associatedField) = list.listProvider.getState() {
                XCTAssertEqual(associatedId, expectedAssociatedId)
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
        case notLoaded(identifiers: [String: String]?)
        case loaded(model: M?)
    }
    
    func assertLazyModel<M: Model>(_ lazyModel: LazyModel<M>,
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
}
