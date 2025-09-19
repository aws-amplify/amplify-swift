//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension TimeInterval {

    static func milliseconds(_ value: Double) -> TimeInterval {
        return value / 1_000
    }

    static func seconds(_ value: Double) -> TimeInterval {
        return value
    }

    static func minutes(_ value: Double) -> TimeInterval {
        return value * 60
    }

    static func hours(_ value: Double) -> TimeInterval {
        return value * 60 * 60
    }

    static func days(_ value: Double) -> TimeInterval {
        return value * 60 * 60 * 24
    }

}
