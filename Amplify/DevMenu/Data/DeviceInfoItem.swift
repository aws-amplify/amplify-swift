//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Data class for a each item shown in the Device Info screen
@available(iOS 13.0.0, *)
struct DeviceInfoItem: Identifiable {
    let id = UUID()
    let type: DeviceInfoItemType

    init(type: DeviceInfoItemType) {
        self.type = type
    }
}
