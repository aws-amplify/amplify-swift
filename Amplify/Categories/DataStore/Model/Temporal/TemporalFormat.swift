//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

    func getFormat(for type: TemporalSpec.Type) -> String {
        if type == Temporal.Time.self {
            return timeFormat
        } else if type == Temporal.Date.self {
            return dateFormat
        }
        return dateTimeFormat
    }

}
