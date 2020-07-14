//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Item types for a row in the Device Info screen
enum DeviceInfoItemType {
    case deviceName(String?)
    case systemName(String?)
    case systemVersion(String?)
    case modelName(String?)
    case localizedModelName(String?)
    case isSimulator(Bool?)
}
