//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Defines the type of query, either a `list` which returns multiple results
/// and can optionally use filters or a `get`, which aims to fetch one result
/// identified by its `id`.
public enum GraphQLQueryType: String {
    case get
    case list
}
