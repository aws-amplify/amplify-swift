//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

/*
 type OIDCGroupPost
   @model
   @auth(
     rules: [
       { allow: owner, provider: oidc, identityClaim: "sub"},
       { allow: groups, provider: oidc, groups: ["Admins"],
                                    groupClaim: "https://myapp.com/claims/groups"}
     ]
   ) {
   id: ID!
   title: String!
   owner: String
 }
 */

public struct OIDCGroupPost: Model {
  public let id: String
  public var title: String
  public var owner: String?

  public init(id: String = UUID().uuidString,
              title: String,
              owner: String? = nil) {
      self.id = id
      self.title = title
      self.owner = owner
  }

    // MARK: - CodingKeys
     public enum CodingKeys: String, ModelKey {
      case id
      case title
      case owner
    }

    public static let keys = CodingKeys.self
    public static let schema = defineSchema { model in
      let oIDCGroupPost = OIDCGroupPost.keys

      model.authRules = [
        rule(allow: .owner,
             ownerField: "owner",
             identityClaim: "sub",
             operations: [.create, .update, .delete, .read]),
        rule(allow: .groups,
             groupClaim: "https://myapp.com/claims/groups",
             groups: ["Admins"],
             operations: [.create, .update, .delete, .read])
      ]

      model.listPluralName = "OIDCGroupPosts"
      model.syncPluralName = "OIDCGroupPosts"

      model.fields(
        .id(),
        .field(oIDCGroupPost.title, is: .required, ofType: .string),
        .field(oIDCGroupPost.owner, is: .optional, ofType: .string)
      )
      }
}

class ModelWithOwnerAuthAndGroupWithGroupClaim: XCTestCase {
    override func setUp() async throws {
        ModelRegistry.register(modelType: OIDCGroupPost.self)
    }

    override func tearDown() async throws {
        ModelRegistry.reset()
    }

    func testOnCreateSubscription_NoGroupInfoPassed() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCGroupPost($owner: String!) {
          onCreateOIDCGroupPost(owner: $owner) {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "123e4567-dead-beef-a456-426614174000")
    }

    func testOnCreateSubscription_InAdminsGroup() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://myapp.com/claims/groups": ["Admins"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCGroupPost {
          onCreateOIDCGroupPost {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssert(document.variables.isEmpty)
    }

    func testOnCreateSubscription_InAdminsGroupAndAnother() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://myapp.com/claims/groups": ["Admins", "Users"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCGroupPost {
          onCreateOIDCGroupPost {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssert(document.variables.isEmpty)
    }

    func testOnCreateSubscription_NotInAdminsGroup() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://myapp.com/claims/groups": ["Users"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCGroupPost($owner: String!) {
          onCreateOIDCGroupPost(owner: $owner) {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "123e4567-dead-beef-a456-426614174000")
    }
}
