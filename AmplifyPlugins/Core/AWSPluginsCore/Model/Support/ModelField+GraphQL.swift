//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Extension that adds GraphQL specific utilities to `ModelField`.
extension ModelField {

    /// The GraphQL name of the field.
    var graphQLName: String {
        if isAssociationOwner, case let .belongsTo(_, targetName) = association {
            return targetName ?? name.pascalCased() + "Id"
        }
        return name
    }
}

extension Array where Element == ModelField {
    var toSelectionSet: [SelectionSetField] {
        var selectionSets = [SelectionSetField]()
        forEach { field in
            let isRequiredAssociation = field.isRequired && field.isAssociationOwner
            if isRequiredAssociation, let associatedModel = field.associatedModel {
                selectionSets.append(SelectionSetField(
                    value: field.name,
                    innerFields: associatedModel.schema.graphQLFields.toSelectionSet))
            } else {
                selectionSets.append(SelectionSetField(value: field.graphQLName))
            }
        }

        selectionSets.append(SelectionSetField(value: "__typename"))

        return selectionSets
    }
}
