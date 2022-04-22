//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@usableFromInline
/// Internal generic method to reduce code reuse in the `init`s of `TemporalSpec`
/// conforming types
internal struct SpecBasedDateConverting<T: _TemporalSpec> {
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
            date = try _Temporal.date(
                from: iso8601String,
                with: T.Format.allFormats
            )
        } else {
            date = try _Temporal.date(
                from: iso8601String,
                with: format.value
            )
        }
        return date
    }
}
