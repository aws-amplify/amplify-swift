//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension TemporalFormat {

    var dateTimeFormat: String {
        switch self {
        case .short:
            return "yyyy-MM-dd'T'HH:mm"
        case .medium:
            return "yyyy-MM-dd'T'HH:mm:ss"
        case .long:
            return "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        case .full:
            return "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        }
    }
}
