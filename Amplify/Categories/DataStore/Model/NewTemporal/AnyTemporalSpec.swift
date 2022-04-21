//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Type-erased protocol for `TemporalSpec` providing access to `iso8601String`
public protocol _AnyTemporalSpec {
    /// The ISO-8601 formatted string in the UTC `TimeZone`.
    var iso8601String: String { get }
}
