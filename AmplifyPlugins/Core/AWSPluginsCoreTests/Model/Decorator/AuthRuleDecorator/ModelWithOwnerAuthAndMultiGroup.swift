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
 type OIDCMultiGroupPost
   @model
   @auth(
     rules: [
    { allow: owner, provider: oidc, identityClaim: "sub"},
    { allow: groups, provider: oidc, groups: ["Admins"],
                                   groupClaim: "https://myapp.com/claims/groups"},
    { allow: groups, provider: oidc, groups: ["Moderators", "Editors"],
                                   groupClaim: "https://differentapp.com/claims/groups"}
     ]
   ) {
   id: ID!
   title: String!
   owner: String
 }
 */

public struct OIDCMultiGroupPost: Model {
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

    public enum CodingKeys: String, ModelKey {
        case id
        case title
        case owner
    }

    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let oIDCMultiGroupPost = OIDCMultiGroupPost.keys

        model.authRules = [
            rule(allow: .owner,
                 ownerField: "owner",
                 identityClaim: "sub",
                 operations: [.create, .update, .delete, .read]),
            rule(allow: .groups,
                 groupClaim: "https://myapp.com/claims/groups",
                 groups: ["Admins"],
                 operations: [.create, .update, .delete, .read]),
            rule(allow: .groups,
                 groupClaim: "https://differentapp.com/claims/groups",
                 groups: ["Moderators", "Editors"],
                 operations: [.create, .update, .delete, .read])
        ]
        model.listPluralName = "OIDCMultiGroupPosts"
        model.syncPluralName = "OIDCMultiGroupPosts"
        model.fields(
            .id(),
            .field(oIDCMultiGroupPost.title, is: .required, ofType: .string),
            .field(oIDCMultiGroupPost.owner, is: .optional, ofType: .string)
        )
    }
}

class ModelWithOwnerAuthAndMultiGroup: XCTestCase {
    override func setUp() async throws {
        ModelRegistry.register(modelType: OIDCMultiGroupPost.self)
    }

    override func tearDown() async throws {
        ModelRegistry.reset()
    }

    func testOnCreateSubscription_NoGroupInfoPassed() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCMultiGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCMultiGroupPost($owner: String!) {
          onCreateOIDCMultiGroupPost(owner: $owner) {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCMultiGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String,
                       "123e4567-dead-beef-a456-426614174000",
                       "owner should exist since there were no groups present in the claims to match the schema")
    }

    func testOnCreateSubscription_InDifferentAppWithModerators() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://differentapp.com/claims/groups": ["Moderators"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCMultiGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCMultiGroupPost {
          onCreateOIDCMultiGroupPost {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCMultiGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty,
                      "variables should be empty since claim group value matches the auth rule schema")
    }

    func testOnCreateSubscription_InDifferentAppWithModeratorsAndEditors() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://differentapp.com/claims/groups": ["Moderators", "Editors"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCMultiGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCMultiGroupPost {
          onCreateOIDCMultiGroupPost {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCMultiGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty,
                      "variables should be empty since claim group value matches the auth rule schema")
    }

    func testOnCreateSubscription_InDifferentAppWithAdminsFromMyApp() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://myapp.com/claims/groups": ["Admins"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCMultiGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCMultiGroupPost {
          onCreateOIDCMultiGroupPost {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCMultiGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty,
                      "variables should be empty since claim group value matches the auth rule schema")
    }

    func testOnCreateSubscription_InAdminsGroupInDifferentClaim() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://differentapp.com/claims/groups": ["Admins"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCMultiGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCMultiGroupPost($owner: String!) {
          onCreateOIDCMultiGroupPost(owner: $owner) {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCMultiGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String,
                       "123e4567-dead-beef-a456-426614174000",
                       "owner should exist since `Admins` is part of myapp.com, not differntapp.com")
    }

    func testOnCreateSubscription_InGroupButNotInSchema() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "https://differentapp.com/claims/groups": ["Users"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: OIDCMultiGroupPost.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateOIDCMultiGroupPost($owner: String!) {
          onCreateOIDCMultiGroupPost(owner: $owner) {
            id
            owner
            title
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateOIDCMultiGroupPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String,
                       "123e4567-dead-beef-a456-426614174000",
                       "owner should exist since `Users` is not part of differentapp.com")
    }
}
