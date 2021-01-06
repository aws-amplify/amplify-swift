//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

extension XCTestExpectation {
    /// Convenience property to help keep long lists of expectations easier to read
    var shouldTrigger: Bool {
        get { !isInverted }
        set { isInverted = !newValue }
    }
}
