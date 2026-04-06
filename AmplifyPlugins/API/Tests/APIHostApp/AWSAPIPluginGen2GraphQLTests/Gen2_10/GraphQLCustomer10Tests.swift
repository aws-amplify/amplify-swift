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

final class GraphQLCustomer10Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/secondary-index/
    func testCodeSnippet() async throws {
        await setup(withModels: Customer10Models())

        let accountRepresentativeId = UUID().uuidString
        let customer = Customer(accountRepresentativeId: accountRepresentativeId)
        _ = try await Amplify.API.mutate(request: .create(customer))

        // Code Snippet Begins
        struct PaginatedList<ModelType: Model>: Decodable {
            let items: [ModelType]
            let nextToken: String?
        }
        let operationName = "listByRep"
        let document = """
        query ListByRep {
          \(operationName)(accountRepresentativeId: "\(accountRepresentativeId)") {
            items {
              accountRepresentativeId
              createdAt
              id
              name
              phoneNumber
              updatedAt
            }
            nextToken
          }
        }
        """

        let request = GraphQLRequest<PaginatedList<Customer>>(
            document: document,
            responseType: PaginatedList<Customer>.self,
            decodePath: operationName
        )

        let queriedCustomers = try await Amplify.API.query(
            request: request).get()

        // Code Snippet Ends
        XCTAssertTrue(!queriedCustomers.items.isEmpty || queriedCustomers.nextToken != nil)
    }
}

extension GraphQLCustomer10Tests: DefaultLogger { }

extension GraphQLCustomer10Tests {
    typealias Customer = Customer10

    struct Customer10Models: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Customer10.self)
        }
    }
}
