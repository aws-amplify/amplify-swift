//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Data class for a row shown in the Developer Menu
@available(iOS 13.0.0, *)
struct DevMenuItem: Identifiable {
    var id = UUID()
    var title: String
    var tag: Int

    init(title: String, tag: Int) {
        self.title = title
        self.tag = tag
    }
}
