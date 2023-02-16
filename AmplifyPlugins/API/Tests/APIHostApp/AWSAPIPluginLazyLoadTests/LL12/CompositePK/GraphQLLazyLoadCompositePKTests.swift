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
    
    func testIncludesAllChildren() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        
        let child = initChild(with: savedParent)
        try await mutate(.create(child))
        let implicitChild = initImplicitChild(with: savedParent)
        try await mutate(.create(implicitChild))
        let explicitChild = initStrangeExplicitChild(with: savedParent)
        try await mutate(.create(explicitChild))
        let sansChild = initChildSansBelongsTo(with: savedParent)
        try await mutate(.create(sansChild))
        
        let request = GraphQLRequest<CompositePKParent>.get(CompositePKParent.self,
                                                            byIdentifier: .identifier(customId: savedParent.customId,
                                                                                      content: savedParent.content),
                                                            includes: { parent in
            [parent.children, parent.implicitChildren, parent.strangeChildren, parent.childrenSansBelongsTo]
        })
        let expectedDocument = """
        query GetCompositePKParent($content: String!, $customId: ID!) {
          getCompositePKParent(content: $content, customId: $customId) {
            customId
            content
            createdAt
            updatedAt
            __typename
            children {
              items {
                childId
                content
                createdAt
                updatedAt
                parent {
                  customId
                  content
                  __typename
                }
                __typename
              }
            }
            implicitChildren {
              items {
                childId
                content
                createdAt
                updatedAt
                parent {
                  customId
                  content
                  __typename
                }
                __typename
              }
            }
            strangeChildren {
              items {
                strangeId
                content
                createdAt
                updatedAt
                parent {
                  customId
                  content
                  __typename
                }
                __typename
              }
            }
            childrenSansBelongsTo {
              items {
                childId
                content
                compositePKParentChildrenSansBelongsToContent
                compositePKParentChildrenSansBelongsToCustomId
                createdAt
                updatedAt
                __typename
              }
            }
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        let queriedParent = try await query(request)!
        XCTAssertNotNil(queriedParent)
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of CompositePKChild
        - Create new CompositePKChild instance with API
     - Then:
        - the newly created instance is successfully created through API. onCreate event is received.
     */
    func testSubscribeCompositePKParentOnCreate() async throws {
        await setup(withModels: CompositePKModels())
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = CompositePKChild(childId: UUID().uuidString, content: UUID().uuidString, parent: parent)
        let (onCreate, subscription) = try await subscribe(of: CompositePKParent.self, type: .onCreate) { createdParent in
            try await createdParent.children?.fetch()
            if case .some(.loaded(let associatedChildren)) = createdParent.children?.loadedState {
                return createdParent.identifier == parent.identifier
                && associatedChildren.map(\.identifier).contains(child.identifier)
            }
            return false
        }

        try await mutate(.create(child))
        try await mutate(.create(parent))
        await waitForExpectations([onCreate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of CompositePKChild
        - Create new CompositePKChild instance with API
        - Create new CompositePKParent instance with API
        - Update the newly created CompositePKParent instance
     - Then:
        - the newly created instance is successfully updated through API. onUpdate event is received.
     */
    func testSubscribeCompositePKParentOnUpdate() async throws {
        await setup(withModels: CompositePKModels())
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = CompositePKChild(childId: UUID().uuidString, content: UUID().uuidString, parent: parent)

        let (onUpdate, subscription) = try await subscribe(of: CompositePKParent.self, type: .onCreate) { updatedParent in
            try await updatedParent.children?.fetch()
            if case .some(.loaded(let associatedChildren)) = updatedParent.children?.loadedState {
                return updatedParent.identifier == parent.identifier
                && associatedChildren.map(\.identifier).contains(child.identifier)
            }
            return false
        }

        try await mutate(.create(child))
        try await mutate(.create(parent))
        try await mutate(.update(parent))
        await waitForExpectations([onUpdate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onDelete events of CompositePKParent
        - Create new CompositePKChild instance with API
        - Create new CompositePKParent instance with API
     - Then:
        - the newly created instance is successfully deleted through API. onDelete event is received.
     */
    func testSubscribeCompositePKParentOnDelete() async throws {
        await setup(withModels: CompositePKModels())

        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = CompositePKChild(childId: UUID().uuidString, content: UUID().uuidString, parent: parent)

        let (onDelete, subscription) = try await subscribe(of: CompositePKParent.self, type: .onDelete) { deletedParent in
            try await deletedParent.children?.fetch()
            if case .some(.loaded(let associatedChildren)) = deletedParent.children?.loadedState {
                return deletedParent.identifier == parent.identifier
                && associatedChildren.map(\.identifier).contains(child.identifier)
            }
            return false
        }

        try await mutate(.create(child))
        try await mutate(.create(parent))
        try await mutate(.delete(parent))
        await waitForExpectations([onDelete], timeout: 10)
        subscription.cancel()
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
    
    func initParent() -> CompositePKParent {
        CompositePKParent(customId: UUID().uuidString,
                          content: "content")
    }
}
