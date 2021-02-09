//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

/// Store metadata about the request alongside AppSync's GraphQL response for a List operation, useful for creating
/// `AppSyncListProvider` that is capable of performing pagination based on the metadata.
public struct AppSyncListPayload: Codable {
    private let variables: [String: JSONValue]?

    let graphQLData: JSONValue
    let apiName: String?
    let documentName: String?

    public init(graphQLData: JSONValue,
                apiName: String?,
                variables: [String: JSONValue]?,
                documentName: String?) {
        self.apiName = apiName
        self.variables = variables
        self.graphQLData = graphQLData
        self.documentName = documentName
    }

    /// Extract from the `variables` object the original GraphQL "filter" is required to perform pagination by
    /// the `AppSyncListProvider` based on the original request filter criteria that was passed in as
    /// a `QueryPredicate`. This may be the association data used if lazy loading was originally performed, or the
    /// predicate that was passed in when retrieving a list (`Amplify.API.query(.paginatedList(where: predicate)`)
    var graphQLFilter: [String: Any]? {
        guard let storedVariables = variables,
           let filters = storedVariables["filter"],
           case let .object(filterValue) = filters else {
            return nil
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        // At this point, there exists a "filter" object that is expected to be successful serialized back to a
        // `GraphQLFilter`.
        guard let filterVariablesData = try? encoder.encode(filterValue),
              let filterVariablesJSON = try? JSONSerialization.jsonObject(with: filterVariablesData)
                as? GraphQLFilter else {

            assert(false, "Filter variables is not a valid JSON object: \(filterValue)")
            return nil
        }

        return filterVariablesJSON
    }

    /// Extract from `variables` object the original GraphQL "limit". This is used to preserve the page size across
    /// multiple pagination calls done using the `AppSyncListProvider`
    var limit: Int? {
        if let storedVariables = variables,
           let limit = storedVariables["limit"],
           case let .number(limitValue) = limit {
            return Int(limitValue)
        }

        return nil
    }

    /// Extract `sort`
    var graphQLSort: [String: Any]? {
        guard let storedVariables = variables,
           let sort = storedVariables["sort"],
           case let .object(sortValue) = sort else {
            return nil
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        guard let sortVariablesData = try? encoder.encode(sortValue),
              let sortVariablesJSON = try? JSONSerialization.jsonObject(with: sortVariablesData)
                as? GraphQLFilter else {

            assert(false, "Filter variables is not a valid JSON object: \(sortValue)")
            return nil
        }

        return sortVariablesJSON
    }

    /// Extrapolate the original type of operation (list or search) based on the document name
    var isSearch: Bool {
        guard let documentName = documentName else {
            return false
        }

        return documentName.starts(with: "search") && documentName.hasSuffix("s")
    }
}
