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

final class GraphQLLazyLoadCompositePKTests: GraphQLLazyLoadBaseTest {

    func testConfigure() async throws {
        await setup(withModels: CompositePKModels())
    }
    
    func testCompositePKParent() async throws {
        await setup(withModels: CompositePKModels())
        
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
        await setup(withModels: CompositePKModels())
        
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
        await setup(withModels: CompositePKModels())
        
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
        await setup(withModels: CompositePKModels())
        
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
                                                                associatedFields: ["parent"]))
        try await queriedParent.children?.fetch()
        assertList(queriedParent.children!, state: .isLoaded(count: 1))
        
        assertList(queriedParent.implicitChildren!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                                queriedParent.content],
                                                                        associatedFields: ["parent"]))
        try await queriedParent.implicitChildren?.fetch()
        assertList(queriedParent.implicitChildren!, state: .isLoaded(count: 1))
        
        assertList(queriedParent.strangeChildren!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                               queriedParent.content],
                                                                       associatedFields: ["parent"]))
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
                                                                             associatedFields: ["compositePKParentChildrenSansBelongsToCustomId"]))
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
        await setup(withModels: CompositePKModels())
        
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

extension GraphQLLazyLoadCompositePKTests: DefaultLogger { }

extension GraphQLLazyLoadCompositePKTests {
    
    struct CompositePKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: CompositePKParent.self)
            ModelRegistry.register(modelType: CompositePKChild.self)
            ModelRegistry.register(modelType: ImplicitChild.self)
            ModelRegistry.register(modelType: StrangeExplicitChild.self)
            ModelRegistry.register(modelType: ChildSansBelongsTo.self)
        }
    }
}
