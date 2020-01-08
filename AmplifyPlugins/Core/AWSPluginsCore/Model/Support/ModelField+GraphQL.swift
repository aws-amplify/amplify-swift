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
    func toSelectionSets(syncEnabled: Bool = false) -> [SelectionSetField] {
        var selectionSets = [SelectionSetField]()
        forEach { field in
            let isRequiredAssociation = field.isRequired && field.isAssociationOwner
            if isRequiredAssociation, let associatedModel = field.associatedModel {
                selectionSets.append(SelectionSetField(
                    value: field.name,
                    innerFields: associatedModel.schema.graphQLFields.toSelectionSets(syncEnabled: syncEnabled)))
            } else {
                selectionSets.append(SelectionSetField(value: field.graphQLName))
            }
        }

        selectionSets.append(SelectionSetField(value: "__typename"))
        if syncEnabled {
            selectionSets.append(SelectionSetField(value: "_version"))
            selectionSets.append(SelectionSetField(value: "_deleted"))
            selectionSets.append(SelectionSetField(value: "_lastChangedAt"))
        }

        return selectionSets
    }
}
