//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date: DateScalar {

    public static var iso8601DateComponents: Set<Calendar.Component> {
        [.year, .month, .day, .timeZone]
    }

    public var date: Date {
        self
    }

    public var dateTime: DateTime {
        DateTime(self)
    }

    public var time: Time {
        Time(self)
    }

    public init(iso8601String: String) throws {
        guard let date = Date.iso8601Date(from: iso8601String) else {
            throw DataStoreError.invalidDateFormat(iso8601String)
        }
        self = date
    }

}
