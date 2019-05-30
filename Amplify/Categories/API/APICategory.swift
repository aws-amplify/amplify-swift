//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class APICategory: BaseCategory<AnyAPICategoryPlugin, AnalyticsPluginSelectorFactory> { }

extension APICategory: APICategoryClientBehavior {
    public func delete() {
        defaultPlugin.delete()
    }

    public func get() {
        defaultPlugin.get()
    }

    public func head() {
        defaultPlugin.head()
    }

    public func options() {
        defaultPlugin.options()
    }

    public func patch() {
        defaultPlugin.patch()
    }

    public func post() {
        defaultPlugin.post()
    }

    public func put() {
        defaultPlugin.put()
    }
}
