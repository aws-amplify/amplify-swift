//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable identifier_name

import Foundation

enum Bytes {
    case terabytes(Int)
    case gigabytes(Int)
    case megabytes(Int)
    case kilobytes(Int)
    case bytes(Int)

    var bytes: UInt64 {
        switch self {
        case .terabytes(let tb):
            return UInt64(pow(1_024.0, 4.0)) * UInt64(tb)
        case .gigabytes(let gb):
            return UInt64(pow(1_024.0, 3.0)) * UInt64(gb)
        case .megabytes(let mb):
            return UInt64(pow(1_024.0, 2.0)) * UInt64(mb)
        case .kilobytes(let kb):
            return 1_024 * UInt64(kb)
        case .bytes(let b):
            return UInt64(b)
        }
    }

    var bits: UInt64 {
        return bytes * 8
    }
}
