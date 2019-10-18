//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Analytics properties can store values of common types
public enum AnalyticsPropertyValue {

    case string(String)

    case int(Int)

    case double(Double)

    case boolean(Bool)
}
