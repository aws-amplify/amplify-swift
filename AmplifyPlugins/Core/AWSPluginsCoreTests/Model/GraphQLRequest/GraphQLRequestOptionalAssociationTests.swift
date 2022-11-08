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

class GraphQLRequestOptionalAssociationTests: XCTestCase {
    override func setUp() {
        ModelRegistry.register(modelType: User.self)
        ModelRegistry.register(modelType: UserFollowing.self)
        ModelRegistry.register(modelType: UserFollowers.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testCreateUserGraphQLRequest() {
        let user = User(name: "username")
        let documentStringValue = """
        mutation CreateUser($input: CreateUserInput!) {
          createUser(input: $input) {
            id
            name
            __typename
          }
        }
        """
        let request = GraphQLRequest<User>.create(user)
        XCTAssertEqual(documentStringValue, request.document)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, user.id)
        XCTAssertEqual(input["name"] as? String, user.name)
    }

    
    func testCreateUserFollowingGraphQLRequest() {
        let user1 = User(name: "user1")
        let user2 = User(name: "user2")
        let userFollowing = UserFollowing(user: user1, followingUser: user2)
        let documentStringValue = """
        mutation CreateUserFollowing($input: CreateUserFollowingInput!) {
          createUserFollowing(input: $input) {
            id
            followingUser {
              id
              __typename
            }
            user {
              id
              __typename
            }
            __typename
          }
        }
        """
        let request = GraphQLRequest<User>.create(userFollowing)
        XCTAssertEqual(documentStringValue, request.document)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, userFollowing.id)
        XCTAssertEqual(input["userFollowingUserId"] as? String, user1.id)
        XCTAssertEqual(input["userFollowingFollowingUserId"] as? String, user2.id)
    }

    func testQueryUserFollowingGraphQLRequest() {
        let documentStringValue = """
        query GetUserFollowing($id: ID!) {
          getUserFollowing(id: $id) {
            id
            followingUser {
              id
              __typename
            }
            user {
              id
              __typename
            }
            __typename
          }
        }
        """
        let request = GraphQLRequest<UserFollowing>.get(UserFollowing.self, byId: "id")
        XCTAssertEqual(documentStringValue, request.document)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }

    func testQueryUserGraphQLRequest() {
        let documentStringValue = """
        query GetUser($id: ID!) {
          getUser(id: $id) {
            id
            name
            __typename
          }
        }
        """
        let request = GraphQLRequest<UserFollowing>.get(User.self, byId: "id")
        XCTAssertEqual(documentStringValue, request.document)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }

    func testListUserFollowingGraphQLRequest() {
        let documentStringValue = """
        query ListUserFollowings($limit: Int) {
          listUserFollowings(limit: $limit) {
            items {
              id
              followingUser {
                id
                __typename
              }
              user {
                id
                __typename
              }
              __typename
            }
            nextToken
          }
        }
        """
        let request = GraphQLRequest<UserFollowing>.list(UserFollowing.self)
        XCTAssertEqual(documentStringValue, request.document)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["limit"] as? Int, 1_000)
    }

    func testSubscribeToUserFollowingGraphQLRequest() {
        let documentStringValue = """
        subscription OnCreateUserFollowing {
          onCreateUserFollowing {
            id
            followingUser {
              id
              __typename
            }
            user {
              id
              __typename
            }
            __typename
          }
        }
        """
        let request = GraphQLRequest<UserFollowing>.subscription(of: UserFollowing.self, type: .onCreate)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssertNil(request.variables)
    }
}
