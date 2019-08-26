//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class StorageRemoveResult {
    public init(key: String) {
        self.key = key
    }
    
    // contains information like the key
    var key: String
}
