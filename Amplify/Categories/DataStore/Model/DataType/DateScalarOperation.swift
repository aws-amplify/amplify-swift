//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DateScalar {

    ///
    /// - Parameters:
    ///   - value: the amount to add, or subtract in case of negative values
    ///   - component: the component that will get the value added
    /// - Returns: a new instance of the current DateScalar type
    func add(value: Int, to component: Calendar.Component) -> Self {
        let calendar = Self.iso8601Calendar
        let result = calendar.date(byAdding: component, value: value, to: self.date)
        guard let date = result else {
            fatalError(
                """
                The Date operation of the component \(component) and value \(value)
                could not be completed. The operation is done on a ISO-8601 Calendar
                and the values passed are not valid in an ISO-8601 context.
                """
            )
        }
        return Self.init(date)
    }

}

/// Defines a common format for a `DateScalar` unit used in operations. It is a tuple
/// of `Calendar.Component`, such as `.year`, and an integer value. Those two are later
/// used in date operations such "4 hours from now" and "2 months ago".
public protocol DateScalarUnit {

    /// The `Calendar.Component` (e.g. `.year`, `.hour`)
    var component: Calendar.Component { get }

    /// The integer value. Must be a valid value for the given `component`
    var value: Int { get }
}
