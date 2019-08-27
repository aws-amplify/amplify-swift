//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public protocol StorageOption {
    var accessLevel: AccessLevel? { get set }
    var options: Any? { get set }
}
