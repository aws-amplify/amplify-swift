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

final class GraphQLLazyLoadHasOneTests: GraphQLLazyLoadBaseTest {

    func testConfigure() async throws {
        await setup(withModels: HasOneParentChildModels(), logLevel: .verbose)
    }
    
    func testHasOneParentChild() async throws {
        await setup(withModels: HasOneParentChildModels(), logLevel: .verbose)
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        let savedParent = try await mutate(.create(hasOneParent))
        
        assertLazyReference(savedParent._child,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedChild.id)]))
        let loadedChild = try await savedParent.child
        assertLazyReference(savedParent._child,
                            state: .loaded(model: loadedChild))
    }
    
    func testHasOneParentChildUpdate() async throws {
        await setup(withModels: HasOneParentChildModels(), logLevel: .verbose)
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        var savedParent = try await mutate(.create(hasOneParent))
        
        let newChild = HasOneChild()
        let savedNewChild = try await mutate(.create(newChild))
        savedParent.setChild(newChild)
        var updatedParent = try await mutate(.update(savedParent))
        
        assertLazyReference(updatedParent._child,
                            state: .notLoaded(identifiers: [.init(name: "id", value: newChild.id)]))
        let loadedChild = try await updatedParent.child
        assertLazyReference(updatedParent._child,
                            state: .loaded(model: loadedChild))
    }
    
    func testHasOneParentChildDelete() async throws {
        await setup(withModels: HasOneParentChildModels(), logLevel: .verbose)
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        var savedParent = try await mutate(.create(hasOneParent))
        
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
        try await assertModelExists(savedChild)
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
    }
    
    func testHasOneParentChildGet() async throws {
        await setup(withModels: HasOneParentChildModels(), logLevel: .verbose)
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        let savedParent = try await mutate(.create(hasOneParent))
        
        let queriedParent = try await query(.get(HasOneParent.self, byId: savedParent.id))!
        assertLazyReference(queriedParent._child,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedChild.id)]))
        let loadedChild = try await queriedParent.child
        assertLazyReference(queriedParent._child,
                            state: .loaded(model: loadedChild))
        
        let queriedChild = try await query(.get(HasOneChild.self, byId: savedChild.id))!
    }
    
    func testHasOneParentChildList() async throws {
        await setup(withModels: HasOneParentChildModels(), logLevel: .verbose)
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        let savedParent = try await mutate(.create(hasOneParent))
        
        let queriedParents = try await listQuery(.list(HasOneParent.self,
                                                       where: HasOneParent.keys.id == hasOneParent.id))
        assertList(queriedParents, state: .isLoaded(count: 1))
        
        let queriedChildren = try await listQuery(.list(HasOneChild.self,
                                                       where: HasOneChild.keys.id == hasOneChild.id))
        assertList(queriedChildren, state: .isLoaded(count: 1))
    }
}

extension GraphQLLazyLoadHasOneTests: DefaultLogger { }

extension GraphQLLazyLoadHasOneTests {
    
    struct HasOneParentChildModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: HasOneParent.self)
            ModelRegistry.register(modelType: HasOneChild.self)
        }
    }
}
