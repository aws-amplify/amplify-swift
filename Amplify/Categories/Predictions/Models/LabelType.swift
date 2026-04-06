//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension Predictions {
    struct LabelType: Equatable, @unchecked Sendable {
        let id: UInt8

        public static let all = Self(id: 0)
        public static let moderation = Self(id: 1)
        public static let labels = Self(id: 2)
    }
}
