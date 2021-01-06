//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A container to hold either an object or a value, useful for storing document inputs and allowing manipulation at
/// the first level of the object
public enum GraphQLDocumentInputValue {
    case scalar(GraphQLDocumentValueRepresentable)
    case object([String: Any?])
}

public protocol GraphQLDocumentValueRepresentable {
    var graphQLDocumentValue: String { get }
}

extension Int: GraphQLDocumentValueRepresentable {
    public var graphQLDocumentValue: String {
        return "\(self)"
    }
}

extension String: GraphQLDocumentValueRepresentable {
    public var graphQLDocumentValue: String {
        return self
    }
}

extension Bool: GraphQLDocumentValueRepresentable {
    public var graphQLDocumentValue: String {
        return "\(self)"
    }
}

extension Decimal: GraphQLDocumentValueRepresentable {
    public var graphQLDocumentValue: String {
        return "\(self)"
    }
}
