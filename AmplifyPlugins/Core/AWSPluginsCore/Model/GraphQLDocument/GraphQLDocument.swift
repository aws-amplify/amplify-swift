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

/// Represents a GraphQL document. Concrete types that conform to this protocol must
/// define a valid GraphQL operation document.
///
/// This type aims to provide an integration between GraphQL and an Amplify `Model`.
/// Therefore, documents represented by concrete implementations provide a single GraphQL
/// operation based on a defined `Model`.
public protocol GraphQLDocument: DataStoreStatement where Variables == [String: Any] {

    /// The `GraphQLDocumentType` a concrete implementation represents the
    /// GraphQL operation of the document
    var documentType: GraphQLDocumentType { get }

    /// The name of the document. This is useful to inspect the response, since it will
    /// contain the name of the document as the key to the response value.
    var name: String { get }

    /// The input variables and types for the document
    /// This should be in the format of `<input parameter variable>: <input parameter type>" and comma separated like
    /// "$input: InputType, $id: ID!"
    var inputTypes: String? { get }

    /// The input parameters and the variables for the document
    /// This should be in the format of `<input parameter name>: <input parameter variable>` and comma separated like
    /// "input: $input, id: $id"
    var inputParameters: String? { get }

    /// The selection set for the document.
    var selectionSetFields: [SelectionSetField] { get }
}

extension GraphQLDocument {

    /// Provides a default empty value to variables so that implementation
    /// becomes optional to document types that don't need to pass variables.
    public var variables: [String: Any] {
        return [:]
    }

    /// Provides default construction of the graphQL document based on values set
    public var stringValue: String {
        let selectionSetString = selectionSetFields.map { $0.toString() }.joined(separator: "\n    ")
        if let inputTypes = inputTypes, let inputParameters = inputParameters {
            return """
            \(documentType) \(name.pascalCased())(\(inputTypes)) {
              \(name)(\(inputParameters)) {
                \(selectionSetString)
              }
            }
            """
        }

        return """
        \(documentType) \(name.pascalCased()) {
          \(name) {
            \(selectionSetString)
          }
        }
        """
    }

    /// Resolve the fields that should be included in the selection set for the `modelType`.
    /// Associated models will be included if they are required and they are the owning
    /// side of the association.
    ///
    /// - Note: Currently implementation assumes the most common and efficient queries.
    /// Future APIs might allow user customization of the selected fields.
    public var selectionSetFields: [SelectionSetField] {
        return modelType.schema.graphQLFields.toSelectionSets()
    }
}
