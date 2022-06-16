//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyDateFormatter {
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

extension DateFormatter: AmplifyDateFormatter {}

extension ISO8601DateFormatter: AmplifyDateFormatter {}
