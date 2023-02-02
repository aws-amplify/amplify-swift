//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

class AWSDataStoreLazyLoadDefaultPKTests: AWSDataStoreLazyLoadBaseTest {
    
    func testStart() async throws {
        await setup(withModels: DefaultPKModels())
        try await startAndWaitForReady()
    }
    
    func testSaveParent() async throws {
        await setup(withModels: DefaultPKModels())
        let parent = Parent()
        try await saveAndWaitForSync(parent)
    }
    
    func testSaveChild() async throws {
        await setup(withModels: DefaultPKModels())
        let parent = Parent()
        let child = Child(parent: parent)
        try await saveAndWaitForSync(parent)
        try await saveAndWaitForSync(child)
    }
    
    func testLazyLoad() async throws {
        await setup(withModels: DefaultPKModels())
        
        let parent = Parent()
        let child = Child(parent: parent)
        let savedParent = try await saveAndWaitForSync(parent)
        let savedChild = try await saveAndWaitForSync(child)
        try await assertChild(savedChild, hasEagerLoaded: savedParent)
        try await assertParent(savedParent, canLazyLoad: savedChild)
        let queriedChild = try await query(for: savedChild)
        try await assertChild(queriedChild, canLazyLoad: savedParent)
        let queriedPost = try await query(for: savedParent)
        try await assertParent(queriedPost, canLazyLoad: savedChild)
    }
    
    func testLazyLoadOnSaveAfterEncodeDecode() async throws {
        await setup(withModels: DefaultPKModels())
        
        let parent = Parent()
        let child = Child(parent: parent)
        let savedParent = try await saveAndWaitForSync(parent)
        let savedChild = try await saveAndWaitForSync(child)
        
        guard let encodedChild = try? savedChild.toJSON() else {
            XCTFail("Could not encode child")
            return
        }
        try await assertChild(savedChild, hasEagerLoaded: savedParent)
        
        guard let decodedChild = try? ModelRegistry.decode(modelName: Child.modelName,
                                                             from: encodedChild) as? Child else {
            
            XCTFail("Could not decode comment")
            return
        }
        
        try await assertChild(decodedChild, hasEagerLoaded: savedParent)
    }
    
    func testLazyLoadOnQueryAfterEncodeDecoder() async throws {
        await setup(withModels: DefaultPKModels())
        
        let parent = Parent()
        let child = Child(parent: parent)
        let savedParent = try await saveAndWaitForSync(parent)
        let savedChild = try await saveAndWaitForSync(child)
        let queriedChild = try await query(for: savedChild)
        
        guard let encodedChild = try? queriedChild.toJSON() else {
            XCTFail("Could not encode child")
            return
        }
        
        try await assertChild(queriedChild, canLazyLoad: savedParent)
        
        guard let decodedChild = try? ModelRegistry.decode(modelName: Child.modelName,
                                                             from: encodedChild) as? Child else {
            
            XCTFail("Could not decode comment")
            return
        }
        
        try await assertChild(decodedChild, canLazyLoad: savedParent)
    }
    
    func assertChild(_ child: Child,
                     hasEagerLoaded parent: Parent) async throws {
        assertLazyReference(child._parent,
                            state: .loaded(model: parent))
        
        guard let loadedParent = try await child.parent else {
            XCTFail("Failed to retrieve the parent from the child")
            return
        }
        XCTAssertEqual(loadedParent.id, parent.id)
        
        try await assertParent(loadedParent, canLazyLoad: child)
    }
    
    func assertChild(_ child: Child,
                       canLazyLoad parent: Parent) async throws {
        assertLazyReference(child._parent,
                        state: .notLoaded(identifiers: [.init(name: "id", value: parent.identifier)]))
        guard let loadedParent = try await child.parent else {
            XCTFail("Failed to load the parent from the child")
            return
        }
        XCTAssertEqual(loadedParent.id, parent.id)
        assertLazyReference(child._parent,
                        state: .loaded(model: parent))
        try await assertParent(loadedParent, canLazyLoad: child)
    }
    
    func assertParent(_ parent: Parent,
                    canLazyLoad child: Child) async throws {
        guard let children = parent.children else {
            XCTFail("Missing children on parent")
            return
        }
        assertList(children, state: .isNotLoaded(associatedIds: [parent.identifier],
                                                 associatedFields: ["parent"]))
        
        try await children.fetch()
        assertList(children, state: .isLoaded(count: 1))
        guard let child = children.first else {
            XCTFail("Missing lazy loaded child from parent")
            return
        }
        
        // further nested models should not be loaded
        assertLazyReference(child._parent,
                        state: .notLoaded(identifiers: [.init(name: "id", value: parent.identifier)]))
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: DefaultPKModels())
        let child = Child(content: "content")
        let savedChild = try await saveAndWaitForSync(child)
        var queriedChild = try await query(for: savedChild)
        assertLazyReference(queriedChild._parent,
                        state: .notLoaded(identifiers: nil))
        let parent = Parent()
        let savedParent = try await saveAndWaitForSync(parent)
        queriedChild.setParent(savedParent)
        let saveCommentWithPost = try await saveAndWaitForSync(queriedChild, assertVersion: 2)
        let queriedChild2 = try await query(for: saveCommentWithPost)
        try await assertChild(queriedChild2, canLazyLoad: parent)
    }
    
    func testUpdateFromqueriedChild() async throws {
        await setup(withModels: DefaultPKModels())
        let parent = Parent()
        let child = Child(parent: parent)
        let savedParent = try await saveAndWaitForSync(parent)
        let savedChild = try await saveAndWaitForSync(child)
        let queriedChild = try await query(for: savedChild)
        assertLazyReference(queriedChild._parent,
                        state: .notLoaded(identifiers: [.init(name: "id", value: parent.identifier)]))
        let savedqueriedChild = try await saveAndWaitForSync(queriedChild, assertVersion: 2)
        let queriedChild2 = try await query(for: savedqueriedChild)
        try await assertChild(queriedChild2, canLazyLoad: savedParent)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: DefaultPKModels())
        
        let parent = Parent()
        let child = Child(parent: parent)
        _ = try await saveAndWaitForSync(parent)
        let savedChild = try await saveAndWaitForSync(child)
        var queriedChild = try await query(for: savedChild)
        assertLazyReference(queriedChild._parent,
                        state: .notLoaded(identifiers: [.init(name: "id", value: parent.identifier)]))
        
        let newParent = DefaultPKParent()
        _ = try await saveAndWaitForSync(newParent)
        queriedChild.setParent(newParent)
        let saveCommentWithNewPost = try await saveAndWaitForSync(queriedChild, assertVersion: 2)
        let queriedChild2 = try await query(for: saveCommentWithNewPost)
        try await assertChild(queriedChild2, canLazyLoad: newParent)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: DefaultPKModels())
        
        let parent = Parent()
        let child = Child(parent: parent)
        _ = try await saveAndWaitForSync(parent)
        let savedChild = try await saveAndWaitForSync(child)
        var queriedChild = try await query(for: savedChild)
        assertLazyReference(queriedChild._parent,
                        state: .notLoaded(identifiers: [.init(name: "id", value: parent.identifier)]))
        
        queriedChild.setParent(nil)
        let saveCommentRemovePost = try await saveAndWaitForSync(queriedChild, assertVersion: 2)
        let queriedChildNoParent = try await query(for: saveCommentRemovePost)
        assertLazyReference(queriedChildNoParent._parent,
                        state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: DefaultPKModels())
        
        let parent = Parent()
        let child = Child(parent: parent)
        let savedParent = try await saveAndWaitForSync(parent)
        let savedChild = try await saveAndWaitForSync(child)
        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedChild)
        try await assertModelDoesNotExist(savedParent)
    }
    
    func testObserveParent() async throws {
        await setup(withModels: DefaultPKModels())
        try await startAndWaitForReady()
        let parent = Parent()
        let child = Child(parent: parent)
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Parent.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedParent = try? mutationEvent.decodeModel(as: Parent.self),
                   receivedParent.id == parent.id {
                    
                    try await saveAndWaitForSync(child)
                    
                    guard let children = receivedParent.children else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await children.fetch()
                    } catch {
                        XCTFail("Failed to lazy load children \(error)")
                    }
                    XCTAssertEqual(children.count, 1)
                    
                    await mutationEventReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: parent, modelSchema: Parent.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveChild() async throws {
        await setup(withModels: DefaultPKModels())
        try await startAndWaitForReady()
        let parent = Parent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = Child(parent: parent)
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Child.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedChild = try? mutationEvent.decodeModel(as: Child.self),
                   receivedChild.id == child.id {
                    try await assertChild(receivedChild, canLazyLoad: savedParent)
                    await mutationEventReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: child, modelSchema: Child.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveQueryParent() async throws {
        await setup(withModels: DefaultPKModels())
        try await startAndWaitForReady()
        let parent = Parent()
        let child = Child(parent: parent)
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Parent.self, where: Parent.keys.id == parent.id)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedParent = querySnapshot.items.first {
                    try await saveAndWaitForSync(child)
                    guard let children = receivedParent.children else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await children.fetch()
                    } catch {
                        XCTFail("Failed to lazy load children \(error)")
                    }
                    XCTAssertEqual(children.count, 1)
                    
                    await snapshotReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: parent, modelSchema: Parent.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
    
    func testObserveQueryChild() async throws {
        await setup(withModels: DefaultPKModels())
        try await startAndWaitForReady()
        
        let parent = Parent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = Child(parent: parent)
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Child.self, where: Child.keys.id == child.id)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedChild = querySnapshot.items.first {
                    try await assertChild(receivedChild, canLazyLoad: savedParent)
                    await snapshotReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: child, modelSchema: Child.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
}

extension AWSDataStoreLazyLoadDefaultPKTests {
    
    typealias Parent = DefaultPKParent
    typealias Child = DefaultPKChild
    
    struct DefaultPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Child.self)
            ModelRegistry.register(modelType: DefaultPKParent.self)
        }
    }
}
