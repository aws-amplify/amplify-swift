//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSPluginsCore

class AuthModeStrategyTests: XCTestCase {

    // Given: default strategy and a model schema
    // When: authTypesFor for .create operation is called
    // Then: an empty iterator is returned
    func testDefaultAuthModeShouldReturnAnEmptyIterator() {
        let authMode = AWSDefaultAuthModeStrategy()
        let authTypesIterator = authMode.authTypesFor(schema: AnyModelTester.schema, operation: .create)
        XCTAssertEqual(authTypesIterator.count, 0)
    }

    // Given: multi-auth strategy and a model schema
    // When: authTypesFor for .create operation is called
    // Then: auth types are returned in order according to priority rules
    func testMultiAuthShouldRespectAuthPriorityRules() async {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = await authMode.authTypesFor(schema: ModelWithOwnerAndPublicAuth.schema, operation: .create)
        XCTAssertEqual(authTypesIterator.count, 2)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .apiKey)
    }

    // Given: multi-auth strategy and a model schema without auth provider
    // When: auth types are requested
    // Then: default values based on the auth strategy should be returned
    func testMultiAuthShouldReturnDefaultAuthTypes() async {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = await authMode.authTypesFor(schema: ModelNoProvider.schema, operation: .read)
        XCTAssertEqual(authTypesIterator.count, 2)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .apiKey)
    }

    // Given: multi-auth strategy and a model schema with 4 auth rules
    // When: authTypesFor for .create operation is called
    // Then: applicable auth types are ordered according to priority rules
    func testMultiAuthPriorityAuthRulesOrder() async {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = await authMode.authTypesFor(schema: ModelAllStrategies.schema, operation: .read)
        XCTAssertEqual(authTypesIterator.count, 4)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .awsIAM)
    }

    // Given: multi-auth strategy and a model schema multiple public rules
    // When: authTypesFor for .create operation is called
    // Then: applicable auth types are ordered according to priority rules
    func testMultiAuthPriorityAuthRulesOrderSameStrategy() async {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = await authMode.authTypesFor(schema: ModelWithMultiplePublicRules.schema, operation: .read)
        XCTAssertEqual(authTypesIterator.count, 4)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .openIDConnect)
        XCTAssertEqual(authTypesIterator.next(), .awsIAM)
        XCTAssertEqual(authTypesIterator.next(), .apiKey)
    }

    // Given: multi-auth strategy and a model schema
    // When: authTypesFor for .create operation is called
    // Then: applicable auth types returned are only the
    //       auth types allowed on the given operation
    func testMultiAuthPriorityAuthPerOperation() async {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = await authMode.authTypesFor(schema: ModelAllStrategies.schema, operation: .create)
        XCTAssertEqual(authTypesIterator.count, 2)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
    }

    // Given: multi-auth strategy a model schema
    // When: authTypesFor for .create operation is called for unauthenticated user
    // Then: applicable auth types returned are only public rules
    func testMultiAuthPriorityUnauthenticatedUser() async {
        let authMode = AWSMultiAuthModeStrategy()
        let delegate = UnauthenticatedUserDelegate()
        authMode.authDelegate = delegate

        var authTypesIterator = await authMode.authTypesFor(schema: ModelWithOwnerAndPublicAuth.schema,
                                                      operation: .create)
        XCTAssertEqual(authTypesIterator.count, 1)
        XCTAssertEqual(authTypesIterator.next(), .apiKey)
    }

    // Given: multi-auth model schema with a custom strategy
    // When: authTypesFor for .create operation is called
    // Then: applicable auth types returned respect the priority rules
    func testMultiAuthPriorityWithCustomStrategy() async {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = await authMode.authTypesFor(schema: ModelWithCustomStrategy.schema,
                                                      operation: .create)
        XCTAssertEqual(authTypesIterator.count, 3)
        XCTAssertEqual(authTypesIterator.next(), .function)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .awsIAM)
    }

    // Given: multi-auth model schema with a custom strategy
    // When: authTypesFor for .create operation is called for unauthenticated user
    // Then: applicable auth types returned are public rules or custom
    func testMultiAuthPriorityUnauthenticatedUserWithCustom() async {
        let authMode = AWSMultiAuthModeStrategy()
        let delegate = UnauthenticatedUserDelegate()
        authMode.authDelegate = delegate

        var authTypesIterator = await authMode.authTypesFor(schema: ModelWithCustomStrategy.schema,
                                                      operation: .create)
        XCTAssertEqual(authTypesIterator.count, 2)
        XCTAssertEqual(authTypesIterator.next(), .function)
        XCTAssertEqual(authTypesIterator.next(), .awsIAM)
    }

}

// MARK: - Test models

/// Model with two auth rules
private struct ModelWithOwnerAndPublicAuth: Model {
    public let id: String

    public enum CodingKeys: String, ModelKey {
        case id
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        model.authRules = [
            rule(allow: .owner, provider: .userPools, operations: [.create, .read, .update, .delete]),
            rule(allow: .public, provider: .apiKey, operations: [.create, .read, .update, .delete])
        ]
    }
}

/// Model with multiple auth rules with equal strategy
private struct ModelWithMultiplePublicRules: Model {
    public let id: String

    public enum CodingKeys: String, ModelKey {
        case id
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        model.authRules = [
            rule(allow: .public, provider: .iam, operations: [.create, .read, .update, .delete]),
            rule(allow: .public, provider: .apiKey, operations: [.create, .read, .update, .delete]),
            rule(allow: .public, provider: .userPools, operations: [.create, .read, .update, .delete]),
            rule(allow: .public, provider: .oidc, operations: [.create, .read, .update, .delete])
        ]
    }
}

/// Model with two auth rules but no auth provider
private struct ModelNoProvider: Model {
    public let id: String

    public enum CodingKeys: String, ModelKey {
        case id
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        model.authRules = [
            rule(allow: .owner, operations: [.create, .read, .update, .delete]),
            rule(allow: .public, operations: [.read])
        ]
    }
}

/// Model with multiple auth rules but no auth provider
private struct ModelAllStrategies: Model {
    public let id: String

    public enum CodingKeys: String, ModelKey {
        case id
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        model.authRules = [
            rule(allow: .owner, provider: .userPools, operations: [.create, .read, .update, .delete]),
            rule(allow: .public, provider: .iam, operations: [.read]),
            rule(allow: .private, provider: .userPools, operations: [.read]),
            rule(allow: .groups, provider: .userPools, operations: [.create, .read])
        ]
    }
}

/// Model with custom auth rule
private struct ModelWithCustomStrategy: Model {
    public let id: String

    public enum CodingKeys: String, ModelKey {
        case id
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        model.authRules = [
            rule(allow: .public, provider: .iam, operations: [.create, .read, .update, .delete]),
            rule(allow: .custom, provider: .function, operations: [.create, .read, .update, .delete]),
            rule(allow: .owner, provider: .userPools, operations: [.create, .read, .update, .delete])
        ]
    }
}

// MARK: Test AuthModeStrategyDelegate

class UnauthenticatedUserDelegate: AuthModeStrategyDelegate {
    func isUserLoggedIn() -> Bool {
        return false
    }
}
