//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyAuthCredentialStoreBehavior {
    func saveCredential(_ credential: Codable) throws
    func retrieveCredential() throws -> Codable
    func deleteCredential() throws

    func saveDevice(_ deviceMetadata: Codable, for username: String) throws
    func retrieveDevice(for username: String) throws -> Codable
    func removeDevice(for username: String) throws
}
