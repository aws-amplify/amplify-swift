//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public typealias GraphQLParameterName = String

/// Represents a single directive GraphQL document. Concrete types that conform to this protocol must
/// define a valid GraphQL operation document.
///
/// This type aims to provide an integration between GraphQL and an Amplify `Model`.
/// Therefore, documents represented by concrete implementations provide a single GraphQL
/// operation based on a defined `Model`.
public protocol SingleDirectiveGraphQLDocument {
    /// The `GraphQLOperationType` a concrete implementation represents the
    /// GraphQL operation of the document
    var operationType: GraphQLOperationType { get }

    /// The name of the document. This is useful to inspect the response, since it will
    /// contain the name of the document as the key to the response value.
    var name: String { get } // * directive

    /// inputs to the graphql Request
    var inputs: [GraphQLParameterName: GraphQLDocumentInput] { get }

    /// The selection set for the document.
    var selectionSetFields: [SelectionSetField] { get }
}

// Provides default implementation
extension SingleDirectiveGraphQLDocument {

    /// Provides a default empty value to variables so that implementation
    /// becomes optional to document types that don't need to pass variables.
    public var variables: [String: Any] {
        var variables = [String: Any]()
        inputs.forEach { input in
            switch input.value.value {
            case .object(let values):
                variables.updateValue(values, forKey: input.key)
            case .value(let value):
                variables.updateValue(value, forKey: input.key)
            }

        }

        return variables
    }

    /// Provides default construction of the graphQL document based on values set
    public var stringValue: String {

        let selectionSetString = selectionSetFields.map { $0.toString() }.joined(separator: "\n    ")
        if !inputs.isEmpty {
            let sortedInputs = inputs.sorted { $0.0 < $1.0 }
            let inputTypes = sortedInputs.map { "$\($0.key): \($0.value.type)" }.joined(separator: ", ")
            let inputParameters = sortedInputs.map { "\($0.key): $\($0.key)" }.joined(separator: ", ")

            return """
            \(operationType.graphQLName) \(name.pascalCased())(\(inputTypes)) {
              \(name)(\(inputParameters)) {
                \(selectionSetString)
              }
            }
            """
        }

        return """
        \(operationType.graphQLName) \(name.pascalCased()) {
          \(name) {
            \(selectionSetString)
          }
        }
        """
    }
}
