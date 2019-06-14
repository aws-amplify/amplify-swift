//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthCategoryPlugin: Plugin, AuthCategoryClientBehavior { }

public extension AuthCategoryPlugin {
    var categoryType: CategoryType {
        return .auth
    }
}

public protocol AuthPluginSelector: PluginSelector, AuthCategoryClientBehavior { }
