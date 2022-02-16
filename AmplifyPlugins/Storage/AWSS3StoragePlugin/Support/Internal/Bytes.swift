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

    var bytes: Int {
        switch self {
        case .terabytes(let tb):
            return Int(pow(1_024.0, 4.0)) * tb
        case .gigabytes(let gb):
            return Int(pow(1_024.0, 3.0)) * gb
        case .megabytes(let mb):
            return Int(pow(1_024.0, 2.0)) * mb
        case .kilobytes(let kb):
            return 1_024 * kb
        case .bytes(let b):
            return b
        }
    }

    var bits: Int {
        return bytes * 8
    }
}
