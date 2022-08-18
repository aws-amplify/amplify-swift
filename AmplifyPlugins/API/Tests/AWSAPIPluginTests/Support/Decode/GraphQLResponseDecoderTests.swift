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

class GraphQLResponseDecoderTests: XCTestCase {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    override func setUp() async throws {
        await Amplify.reset()
        ModelRegistry.register(modelType: SimpleModel.self)
        ModelRegistry.register(modelType: Post4.self)
        ModelRegistry.register(modelType: Comment4.self)
        ModelRegistry.register(modelType: ParentPost4V2.self)
        ModelRegistry.register(modelType: ChildComment4V2.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncListDecoder.self)
        ModelProviderRegistry.registerDecoder(AppSyncModelDecoder.self)

        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
    }

    struct SimpleModel: Model {
        let id: String

        init(id: String = UUID().uuidString) {
            self.id = id
        }

        enum CodingKeys: String, ModelKey {
            case id
        }

        static let keys = CodingKeys.self

        static let schema = defineSchema { model in
            let post = Post.keys
            model.listPluralName = "SimpleModels"
            model.syncPluralName = "SimpleModels"
            model.fields(
                .id()
            )
        }
    }

    struct SimpleCodable: Codable {
        var myBool: Bool
        var myDouble: Double
        var myInt: Int
        var myString: String
        var myDate: Temporal.Date
        var myDateTime: Temporal.DateTime
        var myTime: Temporal.Time
    }

    func testDecodeToGraphQLResponseWhenDataOnly() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ]
        ]
        let data = try encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .success(response) = result else {
            XCTFail("Could not get successful response")
            return
        }
        XCTAssertEqual(response, "{\"id\":\"id\"}")
    }

    func testDecodeToGraphQLResponseWhenErrorsOnly() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "errors": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .failure(response) = result,
              case .error = response else {
            XCTFail("Could not get failure response")
            return
        }
    }

    func testDecodeToGraphQLResponseWhenDataAndErrors() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ],
            "errors": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .failure(response) = result,
              case .partial = response else {
            XCTFail("Could not get failure response")
            return
        }
    }

    func testDecodeToGraphQLResponseWhenInvalidResponse() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "invalidDataKey": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ],
            "invalidErrorsKey": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try encoder.encode(graphQLData)
        decoder.appendResponse(data)

        do {
            _ = try decoder.decodeToGraphQLResponse()
            XCTFail("Should fail in catch block")
        } catch let error as APIError {
            guard case .unknown = error else {
                XCTFail("Unexpected error \(error)")
                return
            }
        } catch {
            XCTFail("Should have been APIError")
        }
    }

    func testDecodeToGraphQLResponseWhenPartialAndDataIsNull() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": JSONValue.null
            ],
            "errors": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .failure(response) = result,
              case .error = response else {
            XCTFail("Could not get failure response")
            return
        }
    }
}
