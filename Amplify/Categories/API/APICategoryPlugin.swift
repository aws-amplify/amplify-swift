//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol APICategoryPlugin: Plugin, APICategoryClientBehavior { }

public extension APICategoryPlugin {
    var categoryType: CategoryType {
        return .api
    }
}
