//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension NewTemporal {
    public struct Date: NewTemporalSpec {
        public let foundationDate: Foundation.Date

        public static func now() -> Self {
            NewTemporal.Date(Foundation.Date())
        }
        
        @inlinable
        @inline(never)
        public init(
            iso8601String: String,
            format: NewTemporal.Date.Format = .unknown
        ) throws {
            let date = try SpecBasedDateConverting<Self>()
                .convert(iso8601String, format)
                        
            self.init(date)
        }
                
        public init(_ date: Foundation.Date) {
            foundationDate = NewTemporal
                .iso8601Calendar
                .startOfDay(for: date)
        }
    }
}

extension NewTemporal.Date {
    public struct Format: TemporalSpecValidFormatRepresentable {
        public let value: String
        
        public static let short: Self = .init(value: "yyyy-MM-dd")
        public static let medium: Self = .init(value: "yyyy-MM-ddZZZZZ")
        public static let long: Self = .init(value: "yyyy-MM-ddZZZZZ")
        public static let full: Self = .init(value: "yyyy-MM-ddZZZZZ")
        public static let unknown: Self = .init(value: "___")
        
        public static let allFormats: [String] = [
            Self.full.value,
            Self.long.value,
            Self.medium.value,
            Self.short.value
        ]
    }
}
