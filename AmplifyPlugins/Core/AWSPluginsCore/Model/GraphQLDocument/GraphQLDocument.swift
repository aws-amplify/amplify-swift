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

    /// The state of the model's backend provisioning, whether it is provisioned with conflict resolution or not.
    var hasSyncableModels: Bool { get }
}

extension GraphQLDocument {

    /// Provides a default empty value to variables so that implementation
    /// becomes optional to document types that don't need to pass variables.
    public var variables: [String: Any] {
        return [:]
    }

    /// Resolve the fields that should be included in the selection set for the `modelType`.
    /// Associated models will be included if they are required and they are the owning
    /// side of the association.
    ///
    /// - Note: Currently implementation assumes the most common and efficient queries.
    /// Future APIs might allow user customization of the selected fields.
    public var selectionSetFields: [String] {
        var fieldSet = [String]()
        let schema = modelType.schema

        var indentSize = 0

        func appendFields(_ fields: [ModelField]) {
            let indent = indentSize == 0 ? "" : String(repeating: "  ", count: indentSize)
            fields.forEach { field in
                let isRequiredAssociation = field.isRequired && field.isAssociationOwner
                if isRequiredAssociation, let associatedModel = field.associatedModel {
                    fieldSet.append(indent + field.name + " {")
                    indentSize += 1
                    appendFields(associatedModel.schema.graphQLFields)
                    indentSize -= 1
                    fieldSet.append(indent + "}")
                } else {
                    fieldSet.append(indent + field.graphQLName)
                }
            }
            fieldSet.append(indent + "__typename")
            if hasSyncableModels {
                fieldSet.append(indent + "_version")
                fieldSet.append(indent + "_deleted")
                fieldSet.append(indent + "_lastChangedAt")
            }
        }
        appendFields(schema.graphQLFields)
        return fieldSet
    }
}
