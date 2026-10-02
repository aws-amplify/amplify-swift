//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import XCTest

import AWSPluginsCore
@testable import Amplify

final class GraphQLStoreBranch7Tests: AWSAPIPluginGen2GraphQLBaseTest, @unchecked Sendable {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/identifiers/#composite-identifier
    func testCodeSnippet() async throws {
        await setup(withModels: StoreBranch7Models())

        _ = try await Amplify.API.query(
            request: .get(
                StoreBranch.self,
                byIdentifier: .identifier(
                    tenantId: "123",
                    name: "Downtown"
                )
            )).get()
    }
}

extension GraphQLStoreBranch7Tests: DefaultLogger { }

extension GraphQLStoreBranch7Tests {
    typealias StoreBranch = StoreBranch7

    struct StoreBranch7Models: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: StoreBranch7.self)
        }
    }
}
