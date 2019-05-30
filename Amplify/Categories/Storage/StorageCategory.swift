//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class StorageCategory: BaseCategory<AnyStorageCategoryPlugin, AnalyticsPluginSelectorFactory> { }

extension StorageCategory: StorageCategoryClientBehavior {
    public func stub() {
        defaultPlugin.stub()
    }
}
