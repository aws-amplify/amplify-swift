//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal.DateTime {
    /// Allowed `Format`s for `Temporal.DateTime`
    ///
    ///  * `.short` => `yyyy-MM-dd'T'HH:mm`
    ///  * `.medium` => `yyyy-MM-dd'T'HH:mm:ss`
    ///  * `.long` => `yyyy-MM-dd'T'HH:mm:ssZZZZZ`
    ///  * `.full` => `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`
    public struct Format: TemporalSpecValidFormatRepresentable {
        public let value: String

        /// `yyyy-MM-dd'T'HH:mm`
        public static let short = Format(value: "yyyy-MM-dd'T'HH:mm")

        /// `yyyy-MM-dd'T'HH:mm:ss`
        public static let medium = Format(value: "yyyy-MM-dd'T'HH:mm:ss")

        /// `yyyy-MM-dd'T'HH:mm:ssZZZZZ`
        public static let long = Format(value: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")

        /// `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`
        public static let full = Format(value: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")

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
