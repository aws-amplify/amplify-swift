//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSAPIPlugin
import AWSCognitoAuthPlugin

@testable import Amplify
@testable import APIHostApp

extension GraphQLWithUserPoolIntegrationTests {
   
    func createTodoAPISwift() async throws {
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let input = APISwift.CreateTodoInput(id: expectedId,
                                             name: expectedName,
                                             description: expectedDescription)
        let mutation = APISwift.CreateTodoMutation(input: input)
        let request = GraphQLRequest(document: APISwift.CreateTodoMutation.operationString,
                                     variables: mutation.variables?.jsonObject,
                                     responseType: APISwift.CreateTodoMutation.Data.self)
        
        
        let event = try await Amplify.API.mutate(request: request)
        switch event {
        case .success(let data):
            guard let todo = data.createTodo else {
                XCTFail("Missing Todo")
                return
            }

            XCTAssertEqual(todo.id, expectedId)
            XCTAssertEqual(todo.name, expectedName)
            XCTAssertEqual(todo.description, expectedDescription)
            XCTAssertEqual(todo.__typename, "Todo")

        case .failure(let error):
            XCTFail("Unexpected .failed event: \(error)")
        }
    }
    
    func testCreateTodoMutationWithUserPoolWithSignedInUserAPISwift() async throws {
        try await createAuthenticatedUser()
        try await createTodoAPISwift()
    }
}
