//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

public class AppSyncListProvider<Element: Model>: ModelListProvider {

    /// The API friendly name used to reference the API to call
    let apiName: String?

    /// The limit for each page size
    var limit: Int? = 1_000

    /// The current state of lazily loaded list
    enum LoadedState {
        /// If the list represents an association between two models, the `associatedIdentifiers` will
        /// hold the information necessary to query the associated elements (e.g. comments of a post)
        ///
        /// The associatedField represents the field to which the owner of the `List` is linked to.
        /// For example, if `Post.comments` is associated with `Comment.post` the `List<Comment>`
        /// of `Post` will have a reference to the `post` field in `Comment`.
        case notLoaded(associatedIdentifiers: [String],
                       associatedField: String)

        /// If the list is retrieved directly, this state holds the underlying data, nextToken used to create
        /// the subsequent GraphQL request, and previous filter used to create the loaded list
        case loaded(elements: [Element],
                    nextToken: String?,
                    filter: [String: Any]?)
    }

    var loadedState: LoadedState

    // MARK: - Initializers

    convenience init(payload: AppSyncListPayload) throws {
        let listResponse = try AppSyncListResponse.initWithMetadata(type: Element.self,
                                                                       graphQLData: payload.graphQLData,
                                                                       apiName: payload.apiName)

        self.init(elements: listResponse.items,
                  nextToken: listResponse.nextToken,
                  apiName: payload.apiName,
                  limit: payload.limit,
                  filter: payload.graphQLFilter)
    }

    convenience init(listResponse: AppSyncListResponse<Element>) throws {
        self.init(elements: listResponse.items,
                  nextToken: listResponse.nextToken)
    }

    convenience init(metadata: AppSyncListDecoder.Metadata) {
        self.init(associatedIdentifiers: metadata.appSyncAssociatedIdentifiers,
                  associatedField: metadata.appSyncAssociatedField,
                  apiName: metadata.apiName)
    }

    // Internal initializer for testing
    init(elements: [Element],
         nextToken: String? = nil,
         apiName: String? = nil,
         limit: Int? = nil,
         filter: [String: Any]? = nil) {
        self.loadedState = .loaded(elements: elements,
                                   nextToken: nextToken,
                                   filter: filter)
        self.apiName = apiName
        self.limit = limit
    }

    // Internal initializer for testing
    init(associatedIdentifiers: [String], associatedField: String, apiName: String? = nil) {
        self.loadedState = .notLoaded(associatedIdentifiers: associatedIdentifiers,
                                      associatedField: associatedField)
        self.apiName = apiName
    }

    // MARK: APIs

    public func getState() -> ModelListProviderState<Element> {
        switch loadedState {
        case .notLoaded(let associatedIdentifiers, let associatedField):
            return .notLoaded(associatedIdentifiers: associatedIdentifiers, associatedField: associatedField)
        case .loaded(let elements, _, _):
            return .loaded(elements)
        }
    }

    public func load() -> Result<[Element], CoreError> {
        switch loadedState {
        case .loaded(let elements, _, _):
            return .success(elements)
        case .notLoaded(let associatedIdentifiers, let associatedField):
            let semaphore = DispatchSemaphore(value: 0)
            var loadResult: Result<[Element], CoreError> = .failure(
                .listOperation("API query failed to complete.",
                               AmplifyErrorMessages.reportBugToAWS(),
                               nil))
            load(associatedIdentifiers: associatedIdentifiers, associatedField: associatedField) { result in
                defer {
                    semaphore.signal()
                }
                switch result {
                case .success(let elements):
                    loadResult = .success(elements)
                case .failure(let error):
                    Amplify.API.log.error(error: error)
                    loadResult = .failure(error)
                }
            }
            semaphore.wait()
            return loadResult
        }
    }

    public func load(completion: @escaping (Result<[Element], CoreError>) -> Void) {
        switch loadedState {
        case .loaded(let elements, _, _):
            completion(.success(elements))
        case .notLoaded(let associatedIdentifiers, let associatedField):
            load(associatedIdentifiers: associatedIdentifiers, associatedField: associatedField, completion: completion)
        }
    }

    //// Internal `load` to perform the retrieval of the first page and storing it in memory
    func load(associatedIdentifiers: [String],
              associatedField: String,
              completion: @escaping (Result<[Element], CoreError>) -> Void ) {
        let filter: GraphQLFilter
        if associatedIdentifiers.count == 1, let associatedId = associatedIdentifiers.first {
            let predicate: QueryPredicate = field(associatedField) == associatedId
            filter = predicate.graphQLFilter(for: Element.schema)
        } else {
            var queryPredicates: [QueryPredicateOperation] = []
            let columnNames = columnNames(field: associatedField, Element.schema)

            let predicateValues = zip(columnNames, associatedIdentifiers)
            for (identifierName, identifierValue) in predicateValues {
                queryPredicates.append(QueryPredicateOperation(field: identifierName,
                                                               operator: .equals(identifierValue)))
            }
            let groupedQueryPredicates = QueryPredicateGroup(type: .and, predicates: queryPredicates)
            filter = groupedQueryPredicates.graphQLFilter(for: Element.schema)
        }

        let request = GraphQLRequest<JSONValue>.listQuery(responseType: JSONValue.self,
                                                          modelSchema: Element.schema,
                                                          filter: filter,
                                                          limit: limit,
                                                          apiName: apiName)
        Amplify.API.query(request: request) { result in
            switch result {
            case .success(let graphQLResponse):
                switch graphQLResponse {
                case .success(let graphQLData):
                    guard let listResponse = try? AppSyncListResponse.initWithMetadata(type: Element.self,
                                                                                       graphQLData: graphQLData,
                                                                                       apiName: self.apiName) else {
                        completion(.failure(CoreError.listOperation("""
                                                The AppSync response return successfully, but could not decode to
                                                AWSAppSyncListResponse from: \(graphQLData)
                                                """, "", nil)))
                        return
                    }

                    self.loadedState = .loaded(elements: listResponse.items,
                                               nextToken: listResponse.nextToken,
                                               filter: filter)
                    completion(.success(listResponse.items))
                case .failure(let graphQLError):
                    Amplify.API.log.error(error: graphQLError)
                    completion(.failure(.listOperation(
                                            "The AppSync response returned successfully with GraphQL errors.",
                                            "Check the underlying error for the failed GraphQL response.",
                                            graphQLError)))
                }
            case .failure(let apiError):
                Amplify.API.log.error(error: apiError)
                completion(.failure(.listOperation("The AppSync request failed",
                                                   "See underlying `APIError` for more details.",
                                                   apiError)))
            }
        }
    }

    public func hasNextPage() -> Bool {
        switch loadedState {
        case .loaded(_, let nextToken, _):
            return nextToken != nil
        case .notLoaded:
            return false
        }
    }

    public func getNextPage(completion: @escaping (Result<List<Element>, CoreError>) -> Void) {
        guard case .loaded(_, let nextTokenOptional, let filter) = loadedState else {
            completion(.failure(.clientValidation("""
                Make sure the underlying data is loaded by calling `load(completion)`, then only call this method when
                `hasNextPage()` is true
                """, "", nil)))
            return
        }
        guard let nextToken = nextTokenOptional else {
            completion(.failure(CoreError.clientValidation("There is no next page.",
                                                           "Only call `getNextPage()` when `hasNextPage()` is true.",
                                                           nil)))
            return
        }

        getNextPage(nextToken: nextToken, filter: filter, completion: completion)
    }

    /// Internal `getNextPage` to retrieve the next page and return it as a new List object
    func getNextPage(nextToken: String,
                     filter: [String: Any]?,
                     completion: @escaping (Result<List<Element>, CoreError>) -> Void) {
        let request = GraphQLRequest<List<Element>>.listQuery(responseType: List<Element>.self,
                                                              modelSchema: Element.schema,
                                                              filter: filter,
                                                              limit: limit,
                                                              nextToken: nextToken,
                                                              apiName: apiName)
        Amplify.API.query(request: request) { result in
            switch result {
            case .success(let graphQLResponse):
                switch graphQLResponse {
                case .success(let nextPageList):
                    completion(.success(nextPageList))
                case .failure(let graphQLError):
                    Amplify.API.log.error(error: graphQLError)
                    completion(.failure(.listOperation("""
                        The AppSync request was processed by the service, but the response contained GraphQL errors.
                        """, "Check the underlying error for the failed GraphQL response.", graphQLError)))
                }
            case .failure(let apiError):
                Amplify.API.log.error(error: apiError)
                completion(.failure(.listOperation("The AppSync request failed",
                                                   "See underlying `APIError` for more details.",
                                                   apiError)))
            }
        }
    }
    public func encode(to encoder: Encoder) throws {
            switch loadedState {
            case .notLoaded(let associatedIdentifiers, let associatedField):
                let metadata = AppSyncListDecoder.Metadata.init(
                    appSyncAssociatedIdentifiers: associatedIdentifiers,
                    appSyncAssociatedField: associatedField,
                    apiName: apiName)
                var container = encoder.singleValueContainer()
                try container.encode(metadata)
            case .loaded(let elements, _, _):
                // This does not encode the `nextToken` or `filter`, which means the data is essentially dropped.
                // If the encoded list is later decoded, the existing `elements` will be available but will be missing
                // the metadata to reflect whether there's a next page or not. Encoding the metadata is rather difficult
                // with the filter being `Any` type and is not a call pattern that is recommended/supported. The extent
                // of this supported flow is to allow encoding and decoding of the `elements`. To get the
                // latest data, make the call to your data source directly through **Amplify.API**.
                try elements.encode(to: encoder)
            }
        }

        // MARK: - Helpers

        /// Retrieve the column names for the specified field `field` for this schema.
        func columnNames(field: String, _ modelSchema: ModelSchema) -> [String] {
            guard let modelField = modelSchema.field(withName: field) else {
                return [field]
            }
            let defaultFieldName = modelSchema.name.camelCased() + field.pascalCased() + "Id"
            switch modelField.association {
            case .belongsTo(_, let targetNames), .hasOne(_, let targetNames):
                guard !targetNames.isEmpty else {
                    return [defaultFieldName]

                }
                return targetNames
            default:
                return [field]
            }
        }

    }

    extension AppSyncListProvider: DefaultLogger { }
