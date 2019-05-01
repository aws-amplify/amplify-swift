//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class AuthCategory: BaseCategory<CategoryMarker.Auth, AnyAuthCategoryPlugin> { }

extension AuthCategory: AuthCategoryClientBehavior {
    public func stub() {
        defaultPlugin.stub()
    }
}
