//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

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

    func testDecodeToResponseTypeForCodable() {

    }
}
