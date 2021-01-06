//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Data class for a row shown in the Developer Menu
@available(iOS 13.0.0, *)
struct DevMenuItem: Identifiable {
    let id = UUID()
    let type: DevMenuItemType

    init(type: DevMenuItemType) {
        self.type = type
    }
}
