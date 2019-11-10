//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The type of a GraphQL operation
public enum GraphQLOperationType {
    /// A GraphQL Query operation
    case query

    /// A GraphQL Mutation operation
    case mutation

    /// A GraphQL Subscription operation
    case subscription
}
