//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryInterceptorBehavior {

    public func addInterceptor() {
        plugin.addInterceptor()
    }

}
