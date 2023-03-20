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
