//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

actor RetryWithJitter {
    let base: UInt
    let max: UInt
    var retryCount: UInt = 0

    init(base: UInt = 25, max: UInt = 6400) {
        self.base = base
        self.max = max
    }

    // using FullJitter backoff strategy
    // ref: https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
    func next() -> UInt {
        let expo = min(max, powerOf2(count: retryCount) * base)
        retryCount += 1
        return UInt.random(in: 0..<expo)
    }

    func reset() {
        self.retryCount = 0
    }
}

fileprivate func powerOf2(count: UInt) -> UInt {
    count == 0
    ? 1
    : 2 * powerOf2(count: count - 1)
}
