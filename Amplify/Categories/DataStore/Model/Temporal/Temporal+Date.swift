//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal {

    /// `Temporal.Date` represents a `Date` with specific allowable formats.
    ///
    ///  * `.short` => `yyyy-MM-dd`
    ///  * `.medium` => `yyyy-MM-ddZZZZZ`
    ///  * `.long` => `yyyy-MM-ddZZZZZ`
    ///  * `.full` => `yyyy-MM-ddZZZZZ`
    ///
    ///  - Note: `.medium`, `.long`, and `.full` are the same date format.
    public struct Date: TemporalSpec {
        // Inherits documentation from `TemporalSpec`
        public let foundationDate: Foundation.Date

        // Inherits documentation from `TemporalSpec`
        public static func now() -> Self {
            Temporal.Date(Foundation.Date())
        }

        @inlinable
        @inline(never)
        // Inherits documentation from `TemporalSpec`
        public init(
            iso8601String: String,
            format: Temporal.Date.Format = .unknown
        ) throws {
            let date = try SpecBasedDateConverting<Self>()
                .convert(iso8601String, format)

            self.init(date)
        }

        // Inherits documentation from `TemporalSpec`
        public init(_ date: Foundation.Date) {
            self.foundationDate = Temporal
                .iso8601Calendar
                .startOfDay(for: date)
        }
    }
}

extension Temporal.Date {

    /// Allowed `Format`s for `Temporal.Date`
    ///
    ///  * `.short` => `yyyy-MM-dd`
    ///  * `.medium` => `yyyy-MM-ddZZZZZ`
    ///  * `.long` => `yyyy-MM-ddZZZZZ`
    ///  * `.full` => `yyyy-MM-ddZZZZZ`
    ///
    ///  - Note: `.medium`, `.long`, and `.full` are the same date format.
    public struct Format: TemporalSpecValidFormatRepresentable {
        public let value: String

        /// `yyyy-MM-dd`
        public static let short = Format(value: "yyyy-MM-dd")

        /// `yyyy-MM-ddZZZZZ`
        public static let medium = Format(value: "yyyy-MM-ddZZZZZ")

        /// `yyyy-MM-ddZZZZZ`
        public static let long = Format(value: "yyyy-MM-ddZZZZZ")

        /// `yyyy-MM-ddZZZZZ`
        public static let full = Format(value: "yyyy-MM-ddZZZZZ")

        // Inherits documentation from `TemporalSpecValidFormatRepresentable`
        public static let unknown = Format(value: "___")

        // Inherits documentation from `TemporalSpecValidFormatRepresentable`
        public static let allFormats: [String] = [
            Self.full.value,
            Self.short.value
        ]
    }
}

// Allow date unit operations on `Temporal.Date`
extension Temporal.Date: DateUnitOperable {}

// Allow `Temporal.Date` to be typed erased
extension Temporal.Date: AnyTemporalSpec {}
