//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension StorageListRequest.Options.SubpathStrategy {
    /// The delimiter for this strategy 
    var delimiter: String? {
        switch self {
        case .exclude(let delimiter):
            return delimiter
        case .include:
            return nil
        }
    }
}
