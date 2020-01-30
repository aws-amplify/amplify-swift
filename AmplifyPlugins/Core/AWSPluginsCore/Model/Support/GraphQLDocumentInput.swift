//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum GraphQLDocumentInputValue {
    case value(Any)
    case object([String: Any?])
}

// Contains information about a parameter and its value to be added to the GraphQLDocument
public struct GraphQLDocumentInput {

    // The string value of the GraphQL type for the GraphQLDocument input
    public var type: String

    // The payload corresponding to the type passed
    public var value: GraphQLDocumentInputValue

    public init(type: String, value: GraphQLDocumentInputValue) {
        self.type = type
        self.value = value
    }
}
