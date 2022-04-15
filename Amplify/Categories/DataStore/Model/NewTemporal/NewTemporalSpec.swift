//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol NewTemporalSpec {
    associatedtype Format: TemporalSpecValidFormatRepresentable
    /// A static builder that return an instance that represent the current point in time.
    static func now() -> Self
    
    /// The underlying `Date` object. All `TemporalSpec` implementations must be backed
    /// by a Foundation `Date` instance.
    var foundationDate: Foundation.Date { get }
    
    /// The ISO-8601 formatted string in the UTC `TimeZone`.
    /// - seealso: iso8601FormattedString(TemporalFormat, TimeZone) -> String
    var iso8601String: String { get }
    
    /// Parses an ISO-8601 `String` into a `TemporalSpec`.
    ///
    /// - Note: if no timezone is present in the string, `.autoupdatingCurrent` is used.
    ///
    /// - Parameter iso8601String: the string in the ISO8601 format
    /// - Throws: `DataStoreError.decodeError`in case the provided string is not
    /// formatted as expected by the scalar type.
    init(iso8601String: String, format: Format) throws
    
    /// Constructs a `TemporalSpec` from a `Date` object.
    /// - Parameter date: the `Date` instance that will be used as the reference of the
    /// `TemporalSpec` instance.
    init(_ date: Foundation.Date)
    
    /// A string representation of the underlying date formatted using ISO8601 rules.
    ///
    /// - Parameters:
    ///   - format: the desired format
    ///   - timeZone: the target `TimeZone`
    /// - Returns: the ISO8601 formatted string in the requested format
    func iso8601FormattedString(format: Format, timeZone: TimeZone) -> String
}

extension NewTemporalSpec {
    
    public func iso8601FormattedString(
        format: Format,
        timeZone: TimeZone = .utc
    ) -> String {
        NewTemporal.string(
            from: foundationDate,
            with: format.value,
            in: timeZone
        )
    }
    
    public var iso8601String: String {
        iso8601FormattedString(format: .full)
    }
}
