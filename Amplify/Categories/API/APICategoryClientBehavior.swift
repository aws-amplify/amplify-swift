//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the API category that clients will use
public protocol APICategoryClientBehavior {
    func delete()
    func get()
    func head()
    func options()
    func patch()
    func post()
    func put()
}
