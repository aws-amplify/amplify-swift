//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLCartCustomer4Tests: AWSAPIPluginGen2GraphQLBaseTest {


    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#create-a-has-one-relationship-between-records
    func testCreate() async throws {
        await setup(withModels: CartCustomer4Models())

        // Code Snippet Begins
        do {
            let customer = Customer(name: "Rene")
            let createdCustomer = try await Amplify.API.mutate(request: .create(customer)).get()

            let cart = Cart(
                items: ["Tomato", "Ice", "Mint"],
                customer: createdCustomer)
            let createdCart = try await Amplify.API.mutate(request: .create(cart)).get()

            // Code Snippet Ends
            let loadedCustomer = try await createdCart.customer
            XCTAssertEqual(loadedCustomer?.id, customer.id)
            // Code Snippet Begins
        } catch {
            print("Create customer or cart failed", error)
            // Code Snippet Ends
            XCTFail("Create customer or cart failed \(error)")
            // Code Snippet Begins
        }
    }

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#update-a-has-one-relationship-between-records
    func testUpdate() async throws {
        await setup(withModels: CartCustomer4Models())
        let customer = Customer(name: "Rene")
        let createdCustomer = try await Amplify.API.mutate(request: .create(customer)).get()
        let cart = Cart(
            items: ["Tomato", "Ice", "Mint"],
            customer: createdCustomer)
        var existingCart = try await Amplify.API.mutate(request: .create(cart)).get()

        // Code Snippet Begins
        do {
            let newCustomer = Customer(name: "Rene")
            let newCustomerCreated = try await Amplify.API.mutate(request: .create(newCustomer)).get()
            existingCart.setCustomer(newCustomerCreated)
            let updatedCart = try await Amplify.API.mutate(request: .update(existingCart)).get()

            // Code Snippet Ends
            let loadedCustomer = try await updatedCart.customer
            XCTAssertEqual(loadedCustomer?.id, newCustomerCreated.id)
            // Code Snippet Begins
        } catch {
            print("Create customer or cart failed", error)
            // Code Snippet Ends
            XCTFail("Create customer or cart failed \(error)")
            // Code Snippet Begins
        }
    }

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#delete-a-has-one-relationship-between-records
    func testDelete() async throws {
        await setup(withModels: CartCustomer4Models())
        let customer = Customer(name: "Rene")
        let createdCustomer = try await Amplify.API.mutate(request: .create(customer)).get()
        let cart = Cart(
            items: ["Tomato", "Ice", "Mint"],
            customer: createdCustomer)
        var existingCart = try await Amplify.API.mutate(request: .create(cart)).get()

        // Code Snippet Begins
        do {
            existingCart.setCustomer(nil)
            let cartWithCustomerRemoved = try await Amplify.API.mutate(request: .update(existingCart)).get()

            // Code Snippet Ends
            let loadedCustomer = try await cartWithCustomerRemoved.customer
            XCTAssertNil(loadedCustomer)
            // Code Snippet Begins
        } catch {
            print("Failed to remove customer from cart", error)
            // Code Snippet Ends
            XCTFail("Failed to remove customer from cart \(error)")
            // Code Snippet Begins
        }
    }

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#delete-a-has-one-relationship-between-records
    func testLoadHasOne() async throws {
        await setup(withModels: CartCustomer4Models())
        let customer = Customer(name: "Rene")
        let createdCustomer = try await Amplify.API.mutate(request: .create(customer)).get()
        let cart = Cart(
            items: ["Tomato", "Ice", "Mint"],
            customer: createdCustomer)
        var existingCart = try await Amplify.API.mutate(request: .create(cart)).get()

        // Code Snippet Begins
        do {
            guard let queriedCart = try await Amplify.API.query(
                request: .get(
                    Cart.self,
                    byIdentifier: existingCart.identifier)).get() else {
                print("Missing cart")
                // Code Snippet Ends
                XCTFail("Missing cart")
                // Code Snippet Begins
                return
            }

            let customer = try await queriedCart.customer

            // Code Snippet Ends
            XCTAssertNotNil(customer)
            // Code Snippet Begins
        } catch {
            print("Failed to fetch cart or customer", error)
            // Code Snippet Ends
            XCTFail("Failed to fetch cart or customer \(error)")
            // Code Snippet Begins
        }
    }
}

extension GraphQLCartCustomer4Tests: DefaultLogger { }

extension GraphQLCartCustomer4Tests {
    typealias Cart = Cart4
    typealias Customer = Customer4

    struct CartCustomer4Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Cart4.self)
            ModelRegistry.register(modelType: Customer4.self)
        }
    }
}
