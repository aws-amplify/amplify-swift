//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3
import ClientRuntime
import AWSClientRuntime

extension StorageError {
    static var serviceKey: String {
        "s3"
    }
}
