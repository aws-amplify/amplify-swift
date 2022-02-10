//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommathAmplify

extension AmplifyBigInt: Equatable, Comparable {

    public static func == (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) == .orderedSame)
    }

    public static func <= (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) != .orderedAscending)
    }

    public static func >= (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) != .orderedDescending)
    }

    public static func > (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) == .orderedAscending)
    }

    public static func < (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) == .orderedDescending)
    }

    func compare(_ againstValue: AmplifyBigInt) -> ComparisonResult {
        let comparisonResult = amplify_mp_cmp(&value, &againstValue.value)

        switch comparisonResult {
        case AMPLIFY_MP_GT:
            return .orderedAscending
        case AMPLIFY_MP_LT:
            return .orderedDescending
        default:
            return .orderedSame
        }
    }
}
