//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Internal generic method to reduce code reuse in the `init`s of `TemporalSpec`
/// conforming types
@usableFromInline
struct SpecBasedDateConverting<Spec: TemporalSpec> {
    @usableFromInline
    typealias DateConverter = (_ string: String, _ format: TemporalFormat?) throws -> (Date, TimeZone)

    @usableFromInline
    let convert: DateConverter

    @inlinable
    @inline(never)
    init(converter: @escaping DateConverter = Self.default) {
        self.convert = converter
    }

    @inlinable
    @inline(never)
    static func `default`(
        iso8601String: String,
        format: TemporalFormat? = nil
    ) throws -> (Date, TimeZone) {
        let date: Foundation.Date
        let tz = TimeZone(iso8601DateString: iso8601String) ?? .utc
        if let format {
            date = try Temporal.date(
                from: iso8601String,
                with: [format(for: Spec.self)]
            )

        } else {
            date = try Temporal.date(
                from: iso8601String,
                with: TemporalFormat.sortedFormats(for: Spec.self)
            )
        }
        return (date, tz)
    }
}
