//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct DeviceMetadataHelper {

    static func getDeviceMetadata(
        for environment: Environment,
        with username: String) async -> DeviceMetadata {
            let credentialStoreClient = (environment as? AuthEnvironment)?.credentialStoreClientFactory()
            do {
                let data = try await credentialStoreClient?.fetchData(type: .deviceMetadata(username: username))

                if case .deviceMetadata(let fetchedMetadata, _) = data {
                    return fetchedMetadata
                } else {
                    return .noData
                }
            } catch {
                let logger = (environment as? LoggerProvider)?.logger
                logger?.error("Unable to fetch device metadata with error: \(error)")
                return .noData
            }
        }

}
