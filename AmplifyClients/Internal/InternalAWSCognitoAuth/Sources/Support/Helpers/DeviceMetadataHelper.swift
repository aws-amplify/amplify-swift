//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
}
