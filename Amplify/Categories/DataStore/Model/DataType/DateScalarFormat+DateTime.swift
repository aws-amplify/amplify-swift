//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DateScalarFormat {

    var dateTimeFormat: String {
        switch self {
        case .short:
            return "yyyy-MM-dd'T'HH:mm"
        case .medium:
            return "yyyy-MM-dd'T'HH:mm:ss"
        case .long:
            return "yyyy-MM-dd'T'HH:mm:ss.SSSS"
        case .full:
            return "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ"
        }
    }
}
