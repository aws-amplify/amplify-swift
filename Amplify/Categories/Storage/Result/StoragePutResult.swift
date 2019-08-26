//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// should we really expose the key?? that is internal to S3....
public class StoragePutResult {
    public init(key: String) {
        self.key = key
    }
    
    // contains information like the key
    var key: String
}
