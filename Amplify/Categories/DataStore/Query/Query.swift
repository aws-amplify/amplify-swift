//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `Query` are structures used to hold the result of a translated `QueryPredicate`. Since predicates
/// are used by models in a generic way, different `QueryTranslator` implementations can produce
/// different outputs for the predicate. For instance, a predicate could be translated to SQL or GraphQL
/// queries and the result and the bound variables (i.e. query input) are represented by `Query`.
public struct Query<Value>: CustomStringConvertible {

    public let string: String
    public let arguments: [Value]

    public init(_ string: String,
                arguments: [Value] = []) {
        self.string = string
        self.arguments = arguments
    }

    public var description: String {
        """
        - Query:
        \(string)

        - Arguments:
        \(String(describing: arguments))
        """
    }

}
