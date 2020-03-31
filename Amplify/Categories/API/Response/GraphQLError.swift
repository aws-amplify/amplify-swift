//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The error format according to https://graphql.github.io/graphql-spec/June2018/#sec-Errors
public protocol GraphQLError: Decodable {

    /// Description of the error
    var message: String { get }

    /// list of locations describing the syntax element
    var locations: [Location]? { get }

    /// Details the path of the response field with error. The values are either strings or 0-index integers
    var path: [JSONValue]? { get }

    /// Additional map of of errors
    var extensions: [String: JSONValue]? { get }
}

/// Both `line` and `column` are positive numbers describing the beginning of an associated syntax element
public struct Location: Decodable {
    public let line: Int
    public let column: Int
}
