//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyAuthCredentialStoreBehavior {
    func saveCredential(_ credential: AmplifyCredentials) throws
    func retrieveCredential() throws -> AmplifyCredentials
    func deleteCredential() throws

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) throws
    func retrieveDevice(for username: String) throws -> DeviceMetadata
    func removeDevice(for username: String) throws

    func saveASFDevice(_ deviceId: String, for username: String) throws
    func retrieveASFDevice(for username: String) throws -> String
    func removeASFDevice(for username: String) throws
}
