//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package enum DeviceMetadataHelper {

    package static func getDeviceMetadata(
        for username: String,
        with environment: Environment
    ) async -> DeviceMetadata {
            let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient
            do {
                let data = try await credentialStoreClient?.fetchData(
                    type: .deviceMetadata(username: username)
                )
                if case .deviceMetadata(let fetchedMetadata, _) = data {
                    return fetchedMetadata
                }
            } catch EngineCredentialStoreError.itemNotFound {
                let logger = (environment as? LoggerProvider)?.logger
                logger?.info("No existing device metadata found.")
            } catch {
                let logger = (environment as? LoggerProvider)?.logger
                logger?.error("Unable to fetch device metadata with error: \(error)")
            }
            return .noData
        }

    package static func removeDeviceMetaData(
        for username: String,
        with environment: Environment
    ) async {
            let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient
            do {
                try await credentialStoreClient?.deleteData(
                    type: .deviceMetadata(username: username)
                )
            } catch {
                let logger = (environment as? LoggerProvider)?.logger
                logger?.error("Unable to remove device metadata with error: \(error)")
            }
        }

    /// Whether `error` is Cognito refusing the device key a request sent: `ResourceNotFoundException` ("Device does
    /// not exist."), for a request that carried device metadata. `forgetDevice` keeps the local record, so the next
    /// sign-in sends the forgotten key.
    package static func isDeviceNotFound(_ error: Error, sent deviceMetadata: DeviceMetadata) -> Bool {
        if case .noData = deviceMetadata {
            return false
        }
        return error is AWSCognitoIdentityProvider.ResourceNotFoundException
    }

    /// Runs `send` with `deviceMetadata`. If Cognito answers that the device does not exist (`isDeviceNotFound`), the
    /// saved device record of `username` is removed and `send` runs once more with no device metadata, as the SRP flow
    /// retries its password verifier. `username` must be the one the record was read with.
    package static func retryingWithoutStaleDevice<Output>(
        _ deviceMetadata: DeviceMetadata,
        for username: String,
        with environment: Environment,
        _ send: (DeviceMetadata) async throws -> Output
    ) async throws -> Output {
        do {
            return try await send(deviceMetadata)
        } catch let error where isDeviceNotFound(error, sent: deviceMetadata) {
            let logger = (environment as? LoggerProvider)?.logger
            logger?.verbose("The saved device is no longer known to Cognito; removing it and retrying without it")
            await removeDeviceMetaData(for: username, with: environment)
            return try await send(.noData)
        }
    }
}
