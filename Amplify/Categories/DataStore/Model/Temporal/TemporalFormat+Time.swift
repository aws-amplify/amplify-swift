//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal.Time {
    /// Allowed `Format`s for `Temporal.Time`
    ///
    ///  * `.short` => `HH:mm`
    ///  * `.medium` => `HH:mm:ss`
    ///  * `.long` => `HH:mm:ss.SSS`
    ///  * `.full` => `HH:mm:ss.SSSZZZZZ`
    public struct Format: TemporalSpecValidFormatRepresentable {
        public let value: String

        /// `HH:mm`
        public static let short = Format(value: "HH:mm")
        /// `HH:mm:ss`
        public static let medium = Format(value: "HH:mm:ss")
        /// `HH:mm:ss.SSS`
        public static let long = Format(value: "HH:mm:ss.SSS")
        /// `HH:mm:ss.SSSZZZZZ`
        public static let full = Format(value: "HH:mm:ss.SSSZZZZZ")

        // Inherits documentation from `TemporalSpecValidFormatRepresentable`
        public static let unknown = Format(value: "___")

        // Inherits documentation from `TemporalSpecValidFormatRepresentable`
        public static let allFormats: [String] = [
            Self.full.value,
            Self.long.value,
            Self.medium.value,
            Self.short.value
        ]
    }
}
