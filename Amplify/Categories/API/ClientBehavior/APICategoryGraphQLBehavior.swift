//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the API category related to GraphQL operations
public protocol APICategoryGraphQLBehavior {
    /// Perform a GraphQL operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameter apiName: name of API being invoked, as specified in `amplifyconfiguration.json`
    /// - Parameter operationType: the GraphQL operation type
    /// - Parameter document: valid GraphQL string
    /// - Parameter classToCast: class to which the result will be cast
    /// - Parameter callback: callback to attach
    /// - Returns: GraphQLQuery query object being enqueued
    func graphql<T: Codable>(apiName: String,
                             operationType: GraphQLOperationType,
                             document: String,
                             classToCast: T.Type,
                             callback: () -> Void) -> GraphQLOperation
}
