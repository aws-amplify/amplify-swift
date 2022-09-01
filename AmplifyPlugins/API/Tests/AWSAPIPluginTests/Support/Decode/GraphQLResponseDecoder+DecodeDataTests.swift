//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin
import AmplifyAsyncTesting

extension GraphQLResponseDecoderTests {

    func testDecodeToResponseTypeForString() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "getSimpleModel": [
                "id": "id"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result, "{\"id\":\"id\"}")
    }

    func testDecodeToResponseTypeForAnyModel() throws {
        ModelRegistry.register(modelType: SimpleModel.self)
        let request = GraphQLRequest<AnyModel>(document: "",
                                              responseType: AnyModel.self,
                                              decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "getSimpleModel": [
                "id": "id",
                "__typename": "SimpleModel"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.id, "id")
        XCTAssertEqual(result.modelName, "SimpleModel")
        guard let simpleModel = result.instance as? SimpleModel else {
            XCTFail("Failed to get SimpleModel")
            return
        }
        XCTAssertEqual(simpleModel.id, "id")
    }

    func testDecodeToResponseTypeForModel() throws {
        let request = GraphQLRequest<SimpleModel>(document: "",
                                                  responseType: SimpleModel.self,
                                                  decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "getSimpleModel": [
                "id": "id"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.id, "id")
    }

    func testDecodeToResponseTypeForModelWithArrayAssoiation() throws {
        let request = GraphQLRequest<Post4>(document: "",
                                            responseType: Post4.self,
                                            decodePath: "getPost")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "getPost": [
                "id": "id",
                "title": "title",
                "__typename": "Post4"
            ]
        ]

        let post = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(post)
        XCTAssertEqual(post.id, "id")
        XCTAssertEqual(post.title, "title")
        XCTAssertNotNil(post.comments)
    }

    func testDecodeToResponseTypeForList() async throws {
        let request = GraphQLRequest<List<SimpleModel>>(document: "",
                                                        responseType: List<SimpleModel>.self,
                                                        decodePath: "listSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "listSimpleModel": [
                "items": [
                    [
                        "id": "id",
                        "__typename": "SimpleModel"
                    ],
                    [
                        "id": "id",
                        "__typename": "SimpleModel"
                    ]
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(result)
        let fetchCompleted = asyncExpectation(description: "Fetch completed")
        Task {
            try await result.fetch()
            XCTAssertEqual(result.count, 2)
            XCTAssertFalse(result.hasNextPage())
            await fetchCompleted.fulfill()
        }
        await waitForExpectations([fetchCompleted], timeout: 1.0)
    }

    func testDecodeToResponseTypeForCodable() throws {

        let request = GraphQLRequest<SimpleCodable>(document: "",
                                                    responseType: SimpleCodable.self,
                                                    decodePath: "getSimpleCodable")
        let graphQLDecoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))

        let expectedObject = SimpleCodable(myBool: true,
                                           myDouble: 1.0,
                                           myInt: 1,
                                           myString: "string",
                                           myDate: .now(),
                                           myDateTime: .now(),
                                           myTime: .now())

        let data = try encoder.encode(expectedObject)
        let objectJSON = try decoder.decode(JSONValue.self, from: data)
        let graphQLData: [String: JSONValue] = [
            "getSimpleCodable": objectJSON
        ]
        let result = try graphQLDecoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.myBool, expectedObject.myBool)
        XCTAssertEqual(result.myDouble, expectedObject.myDouble)
        XCTAssertEqual(result.myInt, expectedObject.myInt)
        XCTAssertEqual(result.myString, expectedObject.myString)
        XCTAssertEqual(result.myDate, expectedObject.myDate)
        XCTAssertEqual(result.myDateTime, expectedObject.myDateTime)
        XCTAssertEqual(result.myTime, expectedObject.myTime)
    }
}
