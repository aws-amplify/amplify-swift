//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

class DataStoreSyncExpressionsTests: SyncEngineIntegrationV2TestBase {
    
    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Team1V2.self)
            registry.register(modelType: Project1V2.self)
        }
        
        let version: String = "1"
    }
    
    /// Given: DataStore configured with syncExpressions
    /// When: Adding models - two matching and one not matching syncExpressions
    /// Then: Receive create mutation only for matching models (filtered out on server side)
    func testSyncModelWithSyncExpressions() async throws {
        let ModelType = Team1V2.self
        
        let incorrectName = "other_name"
        let incorrectModel1Id = UUID().uuidString
        let incorrectModel1 = ModelType.init(id: incorrectModel1Id, name: incorrectName)
        
        let correctName1 = "correct_name_1"
        let correctModel1Id = UUID().uuidString
        let correctModel1 = ModelType.init(id: correctModel1Id, name: correctName1)
        
        let correctName2 = "correct_name_2"
        let correctModel2Id = UUID().uuidString
        let correctModel2 = ModelType.init(id: correctModel2Id, name: correctName2)
        
        let onCreateCorrectModel1 = expectation(description: "Received onCreate for correctModel1")
        let onCreateCorrectModel2 = expectation(description: "Received onCreate for correctModel2")
        
        await setUp(
            withModels: TestModelRegistration(),
            syncExpressions: [
                .syncExpression(ModelType.schema) {
                    QueryPredicateGroup(type: .or, predicates: [
                        ModelType.keys.name.eq(correctName1),
                        ModelType.keys.name.eq(correctName2)
                    ])
                }
            ])
        
        try await startAmplifyAndWaitForSync()
        
        let subscription = Amplify.Publisher.create(Amplify.DataStore.observe(ModelType.self)).sink { completion in
            switch completion {
            case .finished: break
            case .failure(let error): XCTFail("\(error)")
            }
            
        } receiveValue: { mutation in
            guard mutation.mutationType == "create" else { return }
            
            do {
                let createdModelId = try mutation.decodeModel().identifier
                
                if createdModelId == correctModel1Id {
                    onCreateCorrectModel1.fulfill()
                }
                
                if createdModelId == correctModel2Id {
                    onCreateCorrectModel2.fulfill()
                }
                
                if createdModelId == incorrectModel1Id {
                    XCTFail("We should not receive this mutation as it should have been filtered out on the server side")
                }
                
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        _ = try await Amplify.API.mutate(request: .createMutation(of: incorrectModel1)).get()
        _ = try await Amplify.API.mutate(request: .createMutation(of: correctModel1)).get()
        _ = try await Amplify.API.mutate(request: .createMutation(of: correctModel2)).get()
        
        await fulfillment(of: [onCreateCorrectModel1, onCreateCorrectModel2], timeout: TestCommonConstants.networkTimeout)
        
        subscription.cancel()
    }
    
    /// Given: DataStore configured with syncExpressions which causes error "Filters combination exceed maximum limit 10 for subscription." when connecting to sync subscriptions
    /// When: Adding models - two matching and one not matching syncExpressions
    /// Then: Receive create mutation only for matching models (filtered out locally)
    func testSyncModelWithWithTooManyFiltersCombination_FallbackToNoFilterSubscriptions() async throws {
        let ModelType = Team1V2.self
        
        let incorrectName = "other_name"
        let incorrectModel1Id = UUID().uuidString
        let incorrectModel1 = ModelType.init(id: incorrectModel1Id, name: incorrectName)
        
        let correctName1 = "correct_name_1"
        let correctModel1Id = UUID().uuidString
        let correctModel1 = ModelType.init(id: correctModel1Id, name: correctName1)
        
        let correctName2 = "correct_name_2"
        let correctModel2Id = UUID().uuidString
        let correctModel2 = ModelType.init(id: correctModel2Id, name: correctName2)
        
        let onCreateCorrectModel1 = expectation(description: "Received onCreate for correctModel1")
        let onCreateCorrectModel2 = expectation(description: "Received onCreate for correctModel2")
        
        await setUp(
            withModels: TestModelRegistration(),
            syncExpressions: [
                .syncExpression(ModelType.schema) {
                    QueryPredicateGroup(type: .or, predicates:
                                            
                        (0...20).map { ModelType.keys.name.eq("\($0)") }
                        
                        +
                        
                        [
                            ModelType.keys.name.eq(correctName1),
                            ModelType.keys.name.eq(correctName2)
                        ]
                    )
                }
            ])
        
        try await startAmplifyAndWaitForSync()
        
        let subscription = Amplify.Publisher.create(Amplify.DataStore.observe(ModelType.self)).sink { completion in
            switch completion {
            case .finished: break
            case .failure(let error): XCTFail("\(error)")
            }
            
        } receiveValue: { mutation in
            do {
                let createdModelId = try mutation.decodeModel().identifier
                
                if createdModelId == correctModel1Id {
                    onCreateCorrectModel1.fulfill()
                }
                
                if createdModelId == correctModel2Id {
                    onCreateCorrectModel2.fulfill()
                }
                
                if createdModelId == incorrectModel1Id {
                    XCTFail("We should not receive this mutation as it should have been filtered out locally")
                }
                
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        _ = try await Amplify.API.mutate(request: .createMutation(of: incorrectModel1)).get()
        _ = try await Amplify.API.mutate(request: .createMutation(of: correctModel1)).get()
        _ = try await Amplify.API.mutate(request: .createMutation(of: correctModel2)).get()
        
        await fulfillment(of: [onCreateCorrectModel1, onCreateCorrectModel2], timeout: TestCommonConstants.networkTimeout)
        
        subscription.cancel()
    }
}
