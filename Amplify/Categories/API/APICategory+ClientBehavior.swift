//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryClientBehavior {
    public func delete() {
        plugin.delete()
    }

    public func get() {
        plugin.get()
    }

    public func head() {
        plugin.head()
    }

    public func options() {
        plugin.options()
    }

    public func patch() {
        plugin.patch()
    }

    public func post() {
        plugin.post()
    }

    public func put() {
        plugin.put()
    }

}
