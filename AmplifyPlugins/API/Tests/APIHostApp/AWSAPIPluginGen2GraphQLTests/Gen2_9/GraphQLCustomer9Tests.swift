//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLCustomer9Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/secondary-index/
    func testCodeSnippet() async throws {
        await setup(withModels: Customer9Models())

        let accountRepresentativeId = UUID().uuidString
        let name = "Rene"
        let customer = Customer(name: name, accountRepresentativeId: accountRepresentativeId)
        let createdCustomer = try await Amplify.API.mutate(request: .create(customer))

        // Code Snippet Begins
        struct PaginatedList<ModelType: Model>: Decodable {
            let items: [ModelType]
            let nextToken: String?
        }
        let operationName = "listCustomer9ByAccountRepresentativeIdAndName"
        let document = """
        query ListCustomer8ByAccountRepresentativeId {
          \(operationName)(accountRepresentativeId: "\(accountRepresentativeId)", name: {beginsWith: "\(name)"}) {
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
        var request = GraphQLRequest<PaginatedList<Customer>>(
            document: document,
            responseType: PaginatedList<Customer>.self,
            decodePath: operationName)

        let queriedCustomers = try await Amplify.API.query(
            request: request).get()

        // Code Snippet Ends
        XCTAssertTrue(queriedCustomers.items.count != 0 || queriedCustomers.nextToken != nil)
    }
}

extension GraphQLCustomer9Tests: DefaultLogger { }

extension GraphQLCustomer9Tests {
    typealias Customer = Customer9

    struct Customer9Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Customer9.self)
        }
    }
}
