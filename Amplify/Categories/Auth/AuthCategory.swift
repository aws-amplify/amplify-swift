//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class AuthCategory: BaseCategory<AnyAuthCategoryPlugin, AnalyticsPluginSelectorFactory> { }

extension AuthCategory: AuthCategoryClientBehavior {
    public func stub() {
        defaultPlugin.stub()
    }
}
