////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCloudWatchLoggingPlugin

extension RotatingLogBatch: CustomStringConvertible {
    public var description: String {
        return "\((url.path as NSString).lastPathComponent)"
    }
}
