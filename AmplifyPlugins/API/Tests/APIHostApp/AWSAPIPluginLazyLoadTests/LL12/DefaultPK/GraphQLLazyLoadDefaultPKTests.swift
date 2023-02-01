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

final class GraphQLLazyLoadDefaultPKTests: GraphQLLazyLoadBaseTest {

    func testConfigure() async throws {
        await setup(withModels: DefaultPKModels())
    }
    
    func testDefaultPKParentChild() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        assertLazyReference(savedChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedParent.id)]))
        let loadedParent = try await savedChild.parent
        assertLazyReference(savedChild._parent,
                            state: .loaded(model: loadedParent))
    }
    
    func testDefaultParentChildUpdate() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        var savedChild = try await mutate(.create(defaultPKChild))
        
        let newParent = DefaultPKParent()
        let savedNewParent = try await mutate(.create(newParent))
        savedChild.setParent(savedNewParent)
        var updatedChild = try await mutate(.update(savedChild))
                
        assertLazyReference(updatedChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "id", value: newParent.id)]))
        let loadedParent = try await updatedChild.parent
        assertLazyReference(updatedChild._parent,
                            state: .loaded(model: loadedParent))
    }
    
    func testDefaultParentChildDelete() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
        try await assertModelExists(savedChild)
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
    }
    
    func testDefaultPKParentChildGet() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        let queriedParent = try await query(.get(DefaultPKParent.self, byId: savedParent.id))!
        assertList(queriedParent.children!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.id],
                                                                associatedField: "parent"))
        try await queriedParent.children?.fetch()
        assertList(queriedParent.children!, state: .isLoaded(count: 1))
        
        let queriedChild = try await query(.get(DefaultPKChild.self, byId: savedChild.id))!
        assertLazyReference(queriedChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedParent.id)]))
        let loadedParent = try await queriedChild.parent
        assertLazyReference(queriedChild._parent,
                            state: .loaded(model: loadedParent))
    }
    
    func testDefaultPKParentChildList() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        let queriedParents = try await listQuery(.list(DefaultPKParent.self,
                                                       where: DefaultPKParent.keys.id == defaultPKParent.id))
        assertList(queriedParents, state: .isLoaded(count: 1))
        
        let queriedChildren = try await listQuery(.list(DefaultPKChild.self,
                                                        where: DefaultPKChild.keys.id == defaultPKChild.id))
        assertList(queriedChildren, state: .isLoaded(count: 1))
    }
}

extension GraphQLLazyLoadDefaultPKTests: DefaultLogger { }

extension GraphQLLazyLoadDefaultPKTests {
    
    struct DefaultPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: DefaultPKParent.self)
            ModelRegistry.register(modelType: DefaultPKChild.self)
        }
    }
}
