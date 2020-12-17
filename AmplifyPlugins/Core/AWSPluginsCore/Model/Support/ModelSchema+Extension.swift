//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension ModelSchema {

    public func columnName(forField fieldName: String) -> String {
        switch field(withName: fieldName)?.association {
        case .belongsTo(_, let targetName):
            return targetName ?? fieldName
        case .hasOne(_, let targetName):
            return targetName ?? fieldName
        default:
            return fieldName
        }
    }

}
