//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the API category related to REST operations
public protocol APICategoryRESTBehavior {
    /// Perform an HTTP DELETE operation
    func delete()

    /// Perform an HTTP GET operation
    func get()

    /// Perform an HTTP HEAD operation
    func head()

    /// Perform an HTTP OPTIONS operation
    func options()

    /// Perform an HTTP PATCH operation
    func patch()

    /// Perform an HTTP POST operation
    func post()

    /// Perform an HTTP PUT operation
    func put()
}
