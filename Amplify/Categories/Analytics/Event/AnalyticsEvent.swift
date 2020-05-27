//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AnalyticsEvent {

    /// Name of the event
    var name: String { get }

    // Properties of the event
    var properties: AnalyticsProperties? { get }
}
