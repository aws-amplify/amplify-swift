//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `Enum` that represent the different options for formatting ISO8601 values.
/// Each implementation of a `TemporalSpec` is responsible for converting the enum value
/// to a corresponding format string.
public enum TemporalFormat: CaseIterable {

    case short
    case medium
    case long
    case full

}

extension TemporalFormat {

    /// The order in which an implementation of `TemporalSpec` is
    /// parsed matters so no precision is lost. This stored property
    /// represents the order, from the most to the least precise format.
    ///
    /// - Note: if more formats are added to the enum, this property
    /// needs to be updated to reflect the expected parsing order.
    static var sortedCasesForParsing: [TemporalFormat] {
        [.full, .long, .medium, .short]
    }

    func getFormat(for type: TemporalSpec.Type) -> String {
        if type == Temporal.Time.self {
            return timeFormat
        } else if type == Temporal.Date.self {
            return dateFormat
        }
        return dateTimeFormat
    }

}
