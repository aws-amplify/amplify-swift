//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: Resettable {

    public func reset() async {
        await plugin.reset()
        isConfigured = false
    }
}
