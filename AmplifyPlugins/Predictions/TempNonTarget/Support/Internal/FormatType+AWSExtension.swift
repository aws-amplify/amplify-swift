//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension TextFormatType {
    var textractServiceFormatType: [String] {
        switch self {
        case .form:
            return ["FORMS"]
        case .table:
            return ["TABLES"]
        case .all:
            return ["TABLES", "FORMS"]
        default:
            return ["TABLES", "FORMS"]
        }
    }
}
