//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CognitoUserPoolASF {

    static func asfDeviceID(
        for username: String,
        environment: AuthEnvironment) async throws -> String {
            let credentialStoreClient = environment.credentialStoreClientFactory()
            let data = try? await credentialStoreClient.fetchData(
            type: .asfDeviceId(username: username))
            if case .asfDeviceId(let deviceId, _) = data,
               let deviceId = deviceId {
                return deviceId
            }
            let uuid = UUID().uuidString
            try await credentialStoreClient.storeData(data: .asfDeviceId(uuid, username))
            return uuid
        }
}
