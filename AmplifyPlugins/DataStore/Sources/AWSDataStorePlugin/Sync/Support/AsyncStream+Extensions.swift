//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Combine

extension AsyncStream {
    static func from(seq: any Sequence<Element>) -> AsyncStream<Element> {
        AsyncStream { continuation in
            for ele in seq {
                continuation.yield(ele)
            }
            continuation.finish()
        }
    }
}
