//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

public class AppSyncList<ModelType: Model>: List<ModelType>, ModelListDecoder {

    var associatedId: Model.Identifier?
    var associatedField: ModelField?
    var state: LoadState = .pending

    var nextToken: String?
    var document: String?
    var variables: [String: JSONValue]?

    // MARK: - Initializers

    init(_ elements: [Element],
         nextToken: String? = nil,
         document: String? = nil,
         variables: [String: JSONValue]? = nil) {
        super.init(elements)
        self.nextToken = nextToken
        self.document = document
        self.variables = variables
        self.state = .loaded
    }

    public init(_ elements: Elements,
                associatedId: Model.Identifier? = nil,
                associatedField: ModelField? = nil) {
        super.init(elements)
        self.associatedId = associatedId
        self.associatedField = associatedField
    }

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements)
        self.state = .loaded
    }

    // MARK: - Asynchronous API
    public override func fetch(_ completion: @escaping ListCallback<Elements>) {
        fetchLazyLoad(completion)
    }

    func fetchLazyLoad(_ completion: @escaping ListCallback<Elements>) {
        let request = constructGraphQLRequestForFirstPage()
        Amplify.API.query(request: request) { result in
            switch result {
            case .success(let graphQLResponse):
                switch graphQLResponse {
                case .success(let list):
                    self.elements = list.elements
                    self.document = list.document
                    self.variables = list.variables
                    self.nextToken = list.nextToken
                    self.state = .loaded
                    completion(.success(list.elements))
                case .failure(let graphQLError):
                    completion(.failure(.listOperation(
                                            "The AppSync response returned successfully with GraphQL errors.",
                                            "Check the underlying error for the failed GraphQL response.",
                                            graphQLError)))
                }
            case .failure(let apiError):
                completion(.failure(.listOperation("The AppSync request failed",
                                                   "Check the underlying `APIError`",
                                                   apiError)))
            }
        }
    }

    // MARK: Paginatable

    public override func hasNextPage() -> Bool {
        return nextToken != nil
    }

    public override func getNextPage(completion: @escaping PageResultCallback) {
        guard let nextToken = nextToken else {
            completion(.failure(CoreError.validation("There is no next page to fetch.",
                                                     "Check `hasNextPage()` before fetching the next page")))
            return
        }

        let request = reconstructGraphQLRequestForNextPage(nextToken: nextToken)

        Amplify.API.query(request: request) { result in
            switch result {
            case .success(let graphQLResponse):
                switch graphQLResponse {
                case .success(let list):
                    completion(.success(list))
                case .failure(let graphQLError):
                    completion(.failure(.listOperation(
                                            "The AppSync response returned successfully with GraphQL errors.",
                                            "Check the underlying error for the failed GraphQL response.",
                                            graphQLError)))
                }
            case .failure(let apiError):
                completion(.failure(.listOperation("The AppSync request failed",
                                                   "Check the underlying `APIError`",
                                                   apiError)))
            }
        }
    }

    // MARK: ModelListDecoder

    public static func shouldDecode(decoder: Decoder) -> Bool {
        let json = try? JSONValue(from: decoder)

        if case let .object(jsonObject) = json,
           case .array = jsonObject["items"] {
            return true
        }

        if case let .object(jsonObject) = json,
                  case .string = jsonObject["associatedId"],
                  case .string = jsonObject["associatedField"],
                  case .string = jsonObject["listType"] {
            return true
        }

        do {
            _ = try AppSyncListPayload.init(from: decoder)
            return true
        } catch {
            return false
        }
    }

    public static func decode<ModelType: Model>(decoder: Decoder,
                                                modelType: ModelType.Type) -> List<ModelType> {
        do {
            return try AppSyncList<ModelType>.init(from: decoder)
        } catch {
            return List([ModelType]())
        }
    }

    // MARK: Codable

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        // This decoding logic stores the request and response infomation when it detects an `AppSyncListPayload`
        if let payload = try? AppSyncListPayload.init(from: decoder) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try payload.getItems().map { (jsonElement) -> ModelType in
                return try AppSyncList.decodeToModelWithConnections(graphQLData: jsonElement)
            }

            self.init(elements,
                      nextToken: payload.getNextToken(),
                      document: payload.document,
                      variables: payload.variables)
            return
        }

        // This is decoding logic that is run on the first pass to decode the GraphQL response to
        // an `AppSyncList`. Once decoded successfully, the instantiated object is used a detection mechanism
        // to decode an `AppSyncListPayload` a second time to store metadata about the request and response.
        if case let .object(jsonObject) = json,
              case let .array(jsonArray) = jsonObject["items"] {

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try jsonArray.map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            self.init(elements)
            return
        }

        // The is decoding for storing metadata about the Model and its identifier
        // This occurs when the response being decoded is detected to be a `Model` with array associations, then
        // that Model's associations will be decoded with its `associatedId` and `associatedField` to enable lazy
        // fetching of the association.
        if case let .object(jsonObject) = json,
                  case let .string(associatedId) = jsonObject["associatedId"],
                  case let .string(associatedField) = jsonObject["associatedField"],
                  case .string = jsonObject["listType"] {
            let field = Element.schema.field(withName: associatedField)
            self.init([], associatedId: associatedId, associatedField: field)
            return
        }

        self.init([ModelType]())
    }

    static func decodeToModelWithConnections(graphQLData: JSONValue) throws -> ModelType {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy

        let arrayAssociations = ModelType.schema.fields.values.filter {
            $0.isArray && $0.hasAssociation
        }
        guard !arrayAssociations.isEmpty,
              let id = try getId(graphQLData: graphQLData),
              case .object(var graphQLDataObject) = graphQLData else {
            let serializedJSON = try encoder.encode(graphQLData)
            return try decoder.decode(ModelType.self, from: serializedJSON)
        }

        // Iterate over the associations of the model and for each association, store it's association data
        // For example, if the modelType is a Post and has a field that is an array association like Comment
        // Store the post's id and post field in the comments as the `associationPayload`
        ModelType.schema.fields.values.forEach { modelField in
            if modelField.isArray && modelField.hasAssociation,
               let associatedField = modelField.associatedField {
                let modelFieldName = modelField.name
                let associatedFieldName = associatedField.name

                if graphQLData[modelFieldName] == nil {
                    let associationPayload: JSONValue = [
                        "associatedId": .string(id),
                        "associatedField": .string(associatedFieldName),
                        "listType": "appSyncList"
                    ]

                    graphQLDataObject.updateValue(associationPayload, forKey: modelFieldName)
                }
            }
        }

        let serializedJSON = try encoder.encode(graphQLDataObject)
        return try decoder.decode(ModelType.self, from: serializedJSON)
    }

    static func getId(graphQLData: JSONValue) throws -> String? {
        guard case .string(let id) = graphQLData["id"] else {
            Amplify.API.log.error("""
                Could not retrieve the `id` attribute from the return value. Be sure to include `id` in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
                """)
            return nil
        }

        return id
    }
}
