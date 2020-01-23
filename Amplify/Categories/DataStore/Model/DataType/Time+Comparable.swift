//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DateScalar where Self: Comparable {

    public static func == (lhs: Self, rhs: Date) -> Bool {
        return lhs.date == rhs
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.date == rhs.date
    }

    public static func != (lhs: Self, rhs: Date) -> Bool {
        return lhs.date == rhs
    }

    public static func != (lhs: Self, rhs: Self) -> Bool {
        return lhs.date == rhs.date
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.date < rhs.date
    }

    public static func < (lhs: Self, rhs: Date) -> Bool {
        return lhs.date < rhs
    }

    public static func > (lhs: Self, rhs: Self) -> Bool {
        return lhs.date > rhs.date
    }

    public static func > (lhs: Self, rhs: Date) -> Bool {
        return lhs.date > rhs
    }

    public static func <= (lhs: Self, rhs: Self) -> Bool {
        return lhs.date <= rhs.date
    }

    public static func <= (lhs: Self, rhs: Date) -> Bool {
        return lhs.date <= rhs
    }

    public static func >= (lhs: Self, rhs: Self) -> Bool {
        return lhs.date >= rhs.date
    }

    public static func >= (lhs: Self, rhs: Date) -> Bool {
        return lhs.date >= rhs
    }

}
