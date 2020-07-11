//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Data class for a each item shown in the Environment Info screen
@available(iOS 13.0.0, *)
struct EnvironmentInfoItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
