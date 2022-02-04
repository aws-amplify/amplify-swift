//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol CredentialStoreBehavior {

    /** Getting data */
    func getString(_ key: String) throws -> String
    func getData(_ key: String) throws -> Data

    /** Setting data */
    func set(_ value: String, key: String) throws
    func set(_ value: Data, key: String) throws

    /** Removing data */
    func remove(_ key: String) throws
    func removeAll() throws
}
