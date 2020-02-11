//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A container to hold either an object or a value, useful for storing document inputs and allowing manipulation at
/// the first level of the object
public enum GraphQLDocumentInputValue {
    case scalarOrString(Any)
    case object([String: Any?])
}

/// Contains the `type` of the GraphQL document input parameter as a string value and `GraphQLDocumentInputValue`
public struct GraphQLDocumentInput {

    public var type: String

    public var value: GraphQLDocumentInputValue

    public init(type: String, value: GraphQLDocumentInputValue) {
        self.type = type
        self.value = value
    }
}
