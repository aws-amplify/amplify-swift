//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date {
    var unixSeconds: Int64 {
        Int64(timeIntervalSince1970)
    }
}
