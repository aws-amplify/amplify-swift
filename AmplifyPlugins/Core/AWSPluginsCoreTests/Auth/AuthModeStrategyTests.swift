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

    func testDefaultAuthModeShouldReturnAnEmptyIterator() {
        let authMode = AWSDefaultAuthModeStrategy()
        let authTypesIterator = authMode.authTypesFor(schema: AnyModelTester.schema, operation: .create)
        XCTAssertEqual(authTypesIterator.count, 0)
    }

    func testMultiAuthShouldRespectAuthPriorityRules() {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = authMode.authTypesFor(schema: ModelWithOwnerAndPublicAuth.schema, operation: .create)
        XCTAssertEqual(authTypesIterator.count, 2)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .apiKey)
    }

    // Given: multi-auth strategy and a model schema without auth provider
    // When: auth types are requested
    // Then: default values based on the auth strategy should be returned
    func testMultiAuthShouldReturnDefaultAuthTypes() {
        let authMode = AWSMultiAuthModeStrategy()
        var authTypesIterator = authMode.authTypesFor(schema: ModelNoProvider.schema, operation: .create)
        XCTAssertEqual(authTypesIterator.count, 2)
        XCTAssertEqual(authTypesIterator.next(), .amazonCognitoUserPools)
        XCTAssertEqual(authTypesIterator.next(), .apiKey)
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

private struct ModelNoProvider: Model {
    public let id: String

    public enum CodingKeys: String, ModelKey {
        case id
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        model.authRules = [
            rule(allow: .owner, operations: [.create, .read, .update, .delete]),
            rule(allow: .public, operations: [.create, .read, .update, .delete])
        ]
    }
}
