//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DateScalarFormat {

    var timeFormat: String {
        switch self {
        case .short:
            return "HH:mm"
        case .medium:
            return "HH:mm:ss"
        case .long:
            return "HH:mm:ss.SSSS"
        case .full:
            return "HH:mm:ss.SSSSZZZZZ"
        }
    }
}
