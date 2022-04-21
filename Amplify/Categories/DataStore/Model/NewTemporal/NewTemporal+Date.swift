//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension _Temporal {
    public struct Date: _TemporalSpec {
        public let foundationDate: Foundation.Date

        public static func now() -> Self {
            _Temporal.Date(Foundation.Date())
        }
        
        @inlinable
        @inline(never)
        public init(
            iso8601String: String,
            format: _Temporal.Date.Format = .unknown
        ) throws {
            let date = try SpecBasedDateConverting<Self>()
                .convert(iso8601String, format)
                        
            self.init(date)
        }
                
        public init(_ date: Foundation.Date) {
            foundationDate = _Temporal
                .iso8601Calendar
                .startOfDay(for: date)
        }
    }
}

extension _Temporal.Date {
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

extension _Temporal.Date: _DateUnitOperable {}
extension _Temporal.Date: _AnyTemporalSpec {}
