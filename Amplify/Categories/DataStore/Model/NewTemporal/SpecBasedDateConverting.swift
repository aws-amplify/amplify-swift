//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@usableFromInline
internal struct SpecBasedDateConverting<T: NewTemporalSpec> {
    @usableFromInline
    internal typealias DateConverter = (String, T.Format) throws -> Date
    
    @usableFromInline
    internal let convert: DateConverter
    
    @inlinable
    @inline(never)
    init(converter: @escaping DateConverter = Self.default) {
        self.convert = converter
    }
    
    @inlinable
    @inline(never)
    internal static func `default`(
        iso8601String: String,
        format: T.Format
    ) throws -> Date {
        let date: Foundation.Date
        if format == T.Format.unknown {
            date = try NewTemporal.date(
                from: iso8601String,
                with: T.Format.allFormats
            )
        } else {
            date = try NewTemporal.date(
                from: iso8601String,
                with: format.value
            )
        }
        return date
    }
}
