//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin

class MockCredentialStoreBehavior: CredentialStoreBehavior {

    typealias VoidHandler = () -> Void

    let data: String
    let removeAllHandler: VoidHandler?

    init(data: String,
         removeAllHandler: VoidHandler? = nil)
    {
        self.data = data
        self.removeAllHandler = removeAllHandler
    }

    func getString(_ key: String) throws -> String {
        return data
    }

    func getData(_ key: String) throws -> Data {
        return data.data(using: .utf8)!
    }

    func set(_ value: String, key: String) throws { }

    func set(_ value: Data, key: String) throws { }

    func remove(_ key: String) throws {
    }

    func removeAll() throws {
        removeAllHandler?()
    }
}
