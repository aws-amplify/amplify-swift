//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum GraphQLDocumentType: String {
    case mutation
    case query
    case subscription
}

extension String {

    /// Converts a "camelCase" value to "PascalCase". This is a very simple
    /// and naive implementation that assumes the input as a "camelCase" value
    /// and won't perform complex conversions, such as from "snake_case"
    /// or "dash-case" to "PascalCase".
    ///
    /// - Note: this method simply transforms the first character to uppercase.
    ///
    /// - Returns: a string in "PascalCase" converted from "camelCase"
    internal func toPascalCase() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}

/// Represents a GraphQL document. Concrete types that conform to this protocol must
/// define a valid GraphQL operation document.
///
/// This type aims to provide an integration between GraphQL and an Amplify `Model`.
/// Therefore, documents represented by concrete implementations provide a single GraphQL
/// operation based on a defined `Model`.
public protocol GraphQLDocument {
    associatedtype M: Model

    /// The `GraphQLDocumentType` a concrete implementation represents the
    /// GraphQL operation of the document
    var documentType: GraphQLDocumentType { get }

    /// The name of the document. This is useful to inspect the response, since it will
    /// contain the name of the document as the key to the response value.
    var name: String { get }

    /// The `Model` type associated with the document
    var modelType: M.Type { get }

    /// The raw representation of the GraphQL document. This can be used to submit
    /// a `GraphQLRequest` using API operations like `query`, `mutate` and `subscribe`.
    var stringValue: String { get }

    /// The variables that will be passed to the GraphQL endpoint when submiting
    /// the document content return by `stringValue`.
    var variables: [String: Any] { get }
}

extension GraphQLDocument {

    /// Provides a default empty value to variables so that implementation
    /// becomes optional to document types that don't need to pass variables.
    public var variables: [String: Any] {
        return [:]
    }
}
