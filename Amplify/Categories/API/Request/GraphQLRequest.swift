//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Empty protocol for plugins to define specific `AuthorizationMode` types for the request.
/// - Note: `Sendable` because the auth mode is stored on requests that cross task boundaries.
public protocol AuthorizationMode: Sendable { }

/// GraphQL Request
public struct GraphQLRequest<R: Decodable> {

    /// The name of graphQL API being invoked, as specified in `amplifyconfiguration.json`.
    /// Specify this parameter when more than one GraphQL API is configured.
    public let apiName: String?

    /// Query document
    public let document: String

    /// Query variables
    public let variables: [String: Any]?

    /// Type to decode the graphql response data object to
    public let responseType: R.Type

    /// The authorization mode
    public let authMode: AuthorizationMode?

    /// The path to decode to the graphQL response data to `responseType`. Delimited by `.` The decode path
    /// "listTodos.items" will traverse to the object at `listTodos`, and decode the object at `items` to `responseType`
    /// The data at that decode path is a list of Todo objects so `responseType` should be `[Todo].self`
    public let decodePath: String?

    /// Options to adjust the behavior of this request, including plugin-options
    public var options: Options?

    public init(
        apiName: String? = nil,
        document: String,
        variables: [String: Any]? = nil,
        responseType: R.Type,
        decodePath: String? = nil,
        authMode: AuthorizationMode? = nil,
        options: GraphQLRequest<R>.Options? = nil
    ) {
        self.apiName = apiName
        self.document = document
        self.variables = variables
        self.responseType = responseType
        self.authMode = authMode
        self.decodePath = decodePath
        self.options = options
    }
}

// MARK: GraphQLRequest + Options

public extension GraphQLRequest {
    struct Options: @unchecked Sendable {
        // `@unchecked`: `pluginOptions` is `Any?`, which cannot be checked. Narrowing it would be
        // source-breaking for every plugin that passes options through.
        public let pluginOptions: Any?

        public init(pluginOptions: Any?) {
            self.pluginOptions = pluginOptions
        }
    }
}
