//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension TimeInterval {


    /// <#Description#>
    /// - Parameter value: <#value description#>
    /// - Returns: <#description#>
    public static func seconds(_ value: Double) -> TimeInterval {
        return value
    }

    /// <#Description#>
    /// - Parameter value: <#value description#>
    /// - Returns: <#description#>
    public static func minutes(_ value: Double) -> TimeInterval {
        return value * 60
    }

    /// <#Description#>
    /// - Parameter value: <#value description#>
    /// - Returns: <#description#>
    public static func hours(_ value: Double) -> TimeInterval {
        return value * 60 * 60
    }

    /// <#Description#>
    /// - Parameter value: <#value description#>
    /// - Returns: <#description#>
    public static func days(_ value: Double) -> TimeInterval {
        return value * 60 * 60 * 24
    }

}
