//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class StorageListOption: StorageOption {
    internal init(accessLevel: AccessLevel?, options: Any?, prefix: String?, limit: Int?) {
        self.accessLevel = accessLevel
        self.options = options
        self.prefix = prefix
        self.limit = limit
    }
    
    public var accessLevel: AccessLevel?
    
    public var options: Any?
    
    public var limit: Int?
    
    public var prefix: String?
}
