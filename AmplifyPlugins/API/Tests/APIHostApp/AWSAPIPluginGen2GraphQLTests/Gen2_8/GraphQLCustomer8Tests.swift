//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLCustomer8Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/secondary-index/
    func testCodeSnippet() async throws {
        await setup(withModels: Customer8Models())

        let accountRepresentativeId = UUID().uuidString
        let customer = Customer(accountRepresentativeId: accountRepresentativeId)
        _ = try await Amplify.API.mutate(request: .create(customer))

        // Code Snippet Begins
        struct PaginatedList<ModelType: Model>: Decodable {
            let items: [ModelType]
            let nextToken: String?
        }
        let operationName = "listCustomer8ByAccountRepresentativeId"
        let document = """
        query ListCustomer8ByAccountRepresentativeId {
          \(operationName)(accountRepresentativeId: "\(accountRepresentativeId)") {
            items {
              createdAt
              accountRepresentativeId
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
            decodePath: operationName)

        let queriedCustomers = try await Amplify.API.query(
            request: request).get()

        // Code Snippet Ends
        XCTAssertTrue(queriedCustomers.items.count != 0 || queriedCustomers.nextToken != nil)
    }
}

extension GraphQLCustomer8Tests: DefaultLogger { }

extension GraphQLCustomer8Tests {
    typealias Customer = Customer8

    struct Customer8Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Customer8.self)
        }
    }
}
