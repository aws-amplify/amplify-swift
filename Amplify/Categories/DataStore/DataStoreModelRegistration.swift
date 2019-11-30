//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol DataStoreModelRegistration_ {

    func registerModels(_ register: (ModelRegistry.Type) -> Void)

    var version: String { get }
}
