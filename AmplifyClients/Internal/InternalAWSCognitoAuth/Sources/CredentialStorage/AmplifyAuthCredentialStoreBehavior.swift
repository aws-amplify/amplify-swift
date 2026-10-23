//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package protocol AmplifyAuthCredentialStoreBehavior {
    func saveCredential(_ credential: AmplifyCredentials) throws
    func retrieveCredential() throws -> AmplifyCredentials
    func deleteCredential() throws

    // The per-user device and advanced-security records are `async`, so that a host can run their keychain
    // I/O off the cooperative pool (the Cognito client does). A synchronous implementation, such as the
    // plugin's `AWSCognitoAuthCredentialStore`, satisfies them unchanged. Every caller is already `async`.

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) async throws
    func retrieveDevice(for username: String) async throws -> DeviceMetadata
    func removeDevice(for username: String) async throws

    func saveASFDevice(_ deviceId: String, for username: String) async throws
    func retrieveASFDevice(for username: String) async throws -> String
    func removeASFDevice(for username: String) async throws
}
