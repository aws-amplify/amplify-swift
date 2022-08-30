//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Decorates a GraphQL query or mutation with nested/associated properties that should
/// be included in the final selection set.
public struct IncludeAssociationDecorator: ModelBasedGraphQLDocumentDecorator {

    let includedAssociations: [PropertyContainerPath]

    init(_ includedAssociations: [PropertyContainerPath] = []) {
        self.includedAssociations = includedAssociations
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        return decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        if includedAssociations.isEmpty {
            return document
        }
        guard let selectionSet = document.selectionSet else {
            return document
        }

        includedAssociations.forEach { association in
            // we don't include the root reference because it refers to the root model
            // fields in the selection set, only the nested/included ones are needed
            let associationSelectionSet = association.asSelectionSet(includeRoot: false)
            selectionSet.merge(with: associationSelectionSet)
        }

        return document.copy(selectionSet: selectionSet)
    }

}

extension PropertyContainerPath {
    
    func asSelectionSet(includeRoot: Bool = true) -> SelectionSet {
        let metadata = getMetadata()
        let modelName = getModelType().modelName
        guard let schema = ModelRegistry.modelSchema(from: modelName) else {
            fatalError("Schema for model \(modelName) could not be found.")
        }
        let fieldType: SelectionSetFieldType = metadata.isCollection ? .collection : .model
        
        var selectionSet = SelectionSet(value: .init(name: metadata.name, fieldType: fieldType))
        selectionSet.withModelFields(schema.graphQLFields)
        if let parent = metadata.parent as? PropertyContainerPath,
           parent.getMetadata().parent != nil || includeRoot {
            let parentSelectionSet = parent.asSelectionSet(includeRoot: includeRoot)
            parentSelectionSet.replaceChild(selectionSet)
            selectionSet = parentSelectionSet
        }
        return selectionSet
    }

}
