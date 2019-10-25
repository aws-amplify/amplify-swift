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
    /// - Parameter apiName: The name of API being invoked, as specified in `amplifyconfiguration.json`
    /// - Parameter operationType: The GraphQL operation type
    /// - Parameter document: valid GraphQL string
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The GraphQLOperation being enqueued
    func graphql(apiName: String,
                 operationType: GraphQLOperationType,
                 document: String,
                 listener: GraphQLOperation.EventListener?) -> GraphQLOperation
}
