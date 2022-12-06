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

final class GraphQLLazyLoadL12Tests: GraphQLLazyLoadBaseTest {

    func testConfigure() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
    }
    
    // MARK: - HasOneParent / HasOneChild
    
    func testHasOneParentChild() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
    
    // MARK: - DefaultPKParent / DefaultPKChild
    
    func testDefaultPKParentChild() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
        await setup(withModels: LL12Models(), logLevel: .verbose)
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
    
    // MARK: - CompositePKParent
    
    func testCompositePKParent() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
        
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await mutate(.create(compositePKParent))
        let compositePKChild = CompositePKChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedCompositePKChild = try await mutate(.create(compositePKChild))
        let implicitChild = ImplicitChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedImplicitChild = try await mutate(.create(implicitChild))
        let strangeExplicitChild = StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: savedParent)
        let savedStrangeImplicitChild = try await mutate(.create(strangeExplicitChild))
        let childSansBelongsTo = ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: savedParent.customId,
            compositePKParentChildrenSansBelongsToContent: savedParent.content)
        let savedChildSansBelongsTo = try await mutate(.create(childSansBelongsTo))
    }
    
    func testCompositePKParentUpdate() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
        
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await mutate(.create(compositePKParent))
        let compositePKChild = CompositePKChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedCompositePKChild = try await mutate(.create(compositePKChild))
        let implicitChild = ImplicitChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedImplicitChild = try await mutate(.create(implicitChild))
        let strangeExplicitChild = StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: savedParent)
        let savedStrangeImplicitChild = try await mutate(.create(strangeExplicitChild))
        let childSansBelongsTo = ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: savedParent.customId,
            compositePKParentChildrenSansBelongsToContent: savedParent.content)
        let savedChildSansBelongsTo = try await mutate(.create(childSansBelongsTo))
        
    }
    
    func testCompositePKParentDelete() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
        
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await mutate(.create(compositePKParent))
        let compositePKChild = CompositePKChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedCompositePKChild = try await mutate(.create(compositePKChild))
        let implicitChild = ImplicitChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedImplicitChild = try await mutate(.create(implicitChild))
        let strangeExplicitChild = StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: savedParent)
        let savedStrangeImplicitChild = try await mutate(.create(strangeExplicitChild))
        let childSansBelongsTo = ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: savedParent.customId,
            compositePKParentChildrenSansBelongsToContent: savedParent.content)
        let savedChildSansBelongsTo = try await mutate(.create(childSansBelongsTo))
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
        try await mutate(.delete(savedCompositePKChild))
        try await assertModelDoesNotExist(savedCompositePKChild)
        /*
         GraphQLResponseError<ImplicitChild>: GraphQL service returned a successful response containing errors: [Amplify.GraphQLError(message: "Cannot return null for non-nullable type: \'CompositePKParent\' within parent \'ImplicitChild\' (/deleteImplicitChild/parent)", locations: nil, path: Optional([Amplify.JSONValue.string("deleteImplicitChild"), Amplify.JSONValue.string("parent")]), extensions: nil)]
         */
        //try await mutate(.delete(savedImplicitChild))
        //try await assertModelDoesNotExist(savedImplicitChild)
        /*
         GraphQLResponseError<StrangeExplicitChild>: GraphQL service returned a successful response containing errors: [Amplify.GraphQLError(message: "Cannot return null for non-nullable type: \'CompositePKParent\' within parent \'StrangeExplicitChild\' (/deleteStrangeExplicitChild/parent)", locations: nil, path: Optional([Amplify.JSONValue.string("deleteStrangeExplicitChild"), Amplify.JSONValue.string("parent")]), extensions: nil)]
         */
        //try await mutate(.delete(strangeExplicitChild))
        //try await assertModelDoesNotExist(strangeExplicitChild)
    }
    
    func testCompositePKParentGet() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
        
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await mutate(.create(compositePKParent))
        let compositePKChild = CompositePKChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedCompositePKChild = try await mutate(.create(compositePKChild))
        let implicitChild = ImplicitChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedImplicitChild = try await mutate(.create(implicitChild))
        let strangeExplicitChild = StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: savedParent)
        let savedStrangeImplicitChild = try await mutate(.create(strangeExplicitChild))
        let childSansBelongsTo = ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: savedParent.customId,
            compositePKParentChildrenSansBelongsToContent: savedParent.content)
        let savedChildSansBelongsTo = try await mutate(.create(childSansBelongsTo))
        
        // query parent and load the children
        let queriedParent = try await query(.get(CompositePKParent.self,
                                                 byIdentifier: .identifier(customId: savedParent.customId,
                                                                           content: savedParent.content)))!
        assertList(queriedParent.children!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                        queriedParent.content],
                                                                associatedField: "parent"))
        try await queriedParent.children?.fetch()
        assertList(queriedParent.children!, state: .isLoaded(count: 1))
        
        assertList(queriedParent.implicitChildren!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                                queriedParent.content],
                                                                        associatedField: "parent"))
        try await queriedParent.implicitChildren?.fetch()
        assertList(queriedParent.implicitChildren!, state: .isLoaded(count: 1))
        
        assertList(queriedParent.strangeChildren!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                               queriedParent.content],
                                                                       associatedField: "parent"))
        try await queriedParent.strangeChildren?.fetch()
        assertList(queriedParent.strangeChildren!, state: .isLoaded(count: 1))
        
        // Problem: the filter that is created is only on part of the identifier, missing `compositePKParentChildrenSansBelongsToContent`
        /*
         "query" : "query ListChildSansBelongsTos($filter: ModelChildSansBelongsToFilterInput, $limit: Int) {\n  listChildSansBelongsTos(filter: $filter, limit: $limit) {\n    items {\n      childId\n      content\n      compositePKParentChildrenSansBelongsToContent\n      compositePKParentChildrenSansBelongsToCustomId\n      createdAt\n      updatedAt\n      __typename\n    }\n    nextToken\n  }\n}",
         "variables" : {
           "limit" : 1000,
           "filter" : {
             "and" : [
               {
                 "compositePKParentChildrenSansBelongsToCustomId" : {
                   "eq" : "0E05FF6B-3A27-4B4C-B35B-1354FA573961"
                 }
               }
             ]
           }
         }
       }
         */
        assertList(queriedParent.childrenSansBelongsTo!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                                     queriedParent.content],
                                                                             associatedField: "compositePKParentChildrenSansBelongsToCustomId"))
        try await queriedParent.childrenSansBelongsTo?.fetch()
        assertList(queriedParent.childrenSansBelongsTo!, state: .isLoaded(count: 1))
        
        // query children and load the parent - CompositePKChild
        let queriedCompositePKChild = try await query(.get(CompositePKChild.self,
                                                           byIdentifier: .identifier(childId: savedCompositePKChild.childId,
                                                                                     content: savedCompositePKChild.content)))!
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "customId", value: savedParent.customId),
                                                            .init(name: "content", value: savedParent.content)]))
        let loadedParent = try await queriedCompositePKChild.parent
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .loaded(model: loadedParent))
        
        // query children and load the parent - ImplicitChild
        let queriedImplicitChild = try await query(.get(ImplicitChild.self,
                                                           byIdentifier: .identifier(childId: savedImplicitChild.childId,
                                                                                     content: savedImplicitChild.content)))!
        assertLazyReference(queriedImplicitChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "customId", value: savedParent.customId),
                                                            .init(name: "content", value: savedParent.content)]))
        let loadedParent2 = try await queriedImplicitChild.parent
        assertLazyReference(queriedImplicitChild._parent,
                            state: .loaded(model: loadedParent2))
        
        // query children and load the parent - StrangeExplicitChild
        let queriedStrangeImplicitChild = try await query(.get(StrangeExplicitChild.self,
                                                           byIdentifier: .identifier(strangeId: savedStrangeImplicitChild.strangeId,
                                                                                     content: savedStrangeImplicitChild.content)))!
        assertLazyReference(queriedStrangeImplicitChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "customId", value: savedParent.customId),
                                                            .init(name: "content", value: savedParent.content)]))
        let loadedParent3 = try await queriedStrangeImplicitChild.parent
        assertLazyReference(queriedStrangeImplicitChild._parent,
                            state: .loaded(model: loadedParent3))
        
        // query children and verify the parent - ChildSansBelongsTo
        let queriedChildSansBelongsTo = try await query(.get(ChildSansBelongsTo.self,
                                                           byIdentifier: .identifier(childId: savedChildSansBelongsTo.childId,
                                                                                     content: savedChildSansBelongsTo.content)))!
        XCTAssertEqual(queriedChildSansBelongsTo.compositePKParentChildrenSansBelongsToCustomId, savedParent.customId)
        XCTAssertEqual(queriedChildSansBelongsTo.compositePKParentChildrenSansBelongsToContent, savedParent.content)
    }
    
    func testCompositePKParentList() async throws {
        await setup(withModels: LL12Models(), logLevel: .verbose)
        
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await mutate(.create(compositePKParent))
        let compositePKChild = CompositePKChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedCompositePKChild = try await mutate(.create(compositePKChild))
        let implicitChild = ImplicitChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedImplicitChild = try await mutate(.create(implicitChild))
        let strangeExplicitChild = StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: savedParent)
        let savedStrangeImplicitChild = try await mutate(.create(strangeExplicitChild))
        let childSansBelongsTo = ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: savedParent.customId,
            compositePKParentChildrenSansBelongsToContent: savedParent.content)
        let savedChildSansBelongsTo = try await mutate(.create(childSansBelongsTo))
        
        let queriedParents = try await listQuery(.list(CompositePKParent.self,
                                                       where: CompositePKParent.keys.customId == savedParent.customId && CompositePKParent.keys.content == savedParent.content))
        assertList(queriedParents, state: .isLoaded(count: 1))
        
        let queriedImplicitChildren = try await listQuery(.list(ImplicitChild.self,
                                                                where: ImplicitChild.keys.childId == implicitChild.childId && ImplicitChild.keys.content == implicitChild.content))
        assertList(queriedImplicitChildren, state: .isLoaded(count: 1))

        let queriedStrangeChildren = try await listQuery(.list(StrangeExplicitChild.self,
                                                                where: StrangeExplicitChild.keys.strangeId == strangeExplicitChild.strangeId && StrangeExplicitChild.keys.content == strangeExplicitChild.content))
        assertList(queriedStrangeChildren, state: .isLoaded(count: 1))
        
        let queriedChildSansBelongsToChildren = try await listQuery(.list(ChildSansBelongsTo.self,
                                                                where: ChildSansBelongsTo.keys.childId == childSansBelongsTo.childId && ChildSansBelongsTo.keys.content == childSansBelongsTo.content))
        assertList(queriedChildSansBelongsToChildren, state: .isLoaded(count: 1))
    }
}

extension GraphQLLazyLoadL12Tests: DefaultLogger { }

extension GraphQLLazyLoadL12Tests {
    
    struct LL12Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: HasOneParent.self)
            ModelRegistry.register(modelType: HasOneChild.self)
            ModelRegistry.register(modelType: DefaultPKParent.self)
            ModelRegistry.register(modelType: DefaultPKChild.self)
            ModelRegistry.register(modelType: CompositePKParent.self)
            ModelRegistry.register(modelType: CompositePKChild.self)
            ModelRegistry.register(modelType: ImplicitChild.self)
            ModelRegistry.register(modelType: StrangeExplicitChild.self)
            ModelRegistry.register(modelType: ChildSansBelongsTo.self)
        }
    }
}
