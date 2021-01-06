//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension TemporalFormat {

    var dateFormat: String {
        switch self {
        case .short:
            return "yyyy-MM-dd"
        case .medium:
            return "yyyy-MM-ddZZZZZ"
        case .long:
            return "yyyy-MM-ddZZZZZ"
        case .full:
            return "yyyy-MM-ddZZZZZ"
        }
    }
}
