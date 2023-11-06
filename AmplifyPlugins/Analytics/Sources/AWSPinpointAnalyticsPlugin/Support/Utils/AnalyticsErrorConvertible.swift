//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError { get }
}

extension AnalyticsError: AnalyticsErrorConvertible {
    var analyticsError: AnalyticsError {
        self
    }
}
