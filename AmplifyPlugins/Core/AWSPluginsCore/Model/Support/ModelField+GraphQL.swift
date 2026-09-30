//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Extension that adds GraphQL specific utilities to `ModelField`.
extension ModelField {

    /// The GraphQL name of the field.
    var graphQLName: String {
        if isAssociationOwner, case let .belongsTo(_, targetNames) = association {
            return targetNames.first ?? name.pascalCased() + "Id"
        }
        return name
    }

    /// Foreign-key field name(s) backing a `belongsTo`/`hasOne` association; empty otherwise.
    var _associationTargetNames: [String] { // swiftlint:disable:this identifier_name
        switch association {
        case let .belongsTo(_, targetNames):
            return targetNames
        case let .hasOne(_, _, targetNames):
            return targetNames
        default:
            return []
        }
    }
}
