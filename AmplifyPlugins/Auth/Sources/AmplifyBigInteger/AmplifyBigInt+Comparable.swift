//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommath

extension AmplifyBigInt: Equatable, Comparable {
    
    static public func == (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) == .orderedSame)
    }

    static public func <= (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) != .orderedAscending)
    }

    static public func >= (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) != .orderedDescending)
    }

    static public func > (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) == .orderedAscending)
    }

    static public func < (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Bool {
        return (lhs.compare(rhs) == .orderedDescending)
    }
    
    func compare(_ againstValue: AmplifyBigInt) -> ComparisonResult {
        let comparisonResult = mp_cmp(&value, &againstValue.value)
        
        switch comparisonResult {
        case MP_GT:
            return .orderedAscending
        case MP_LT:
            return .orderedDescending
        default:
            return .orderedSame
        }
    }
}
