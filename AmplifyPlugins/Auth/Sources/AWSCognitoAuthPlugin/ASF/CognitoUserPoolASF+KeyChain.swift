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
        credentialStoreClient: CredentialStoreStateBehavior) async throws -> String {
            let deviceMetaDataType = CredentialStoreDataType.deviceMetadata(username: username)
            let data = try? await credentialStoreClient.fetchData(type: deviceMetaDataType)
            if case .deviceMetadata(let metadata, _) = data,
               case .metadata(let deviceData) = metadata {
                return deviceData.deviceKey
            }

            let dataType = CredentialStoreDataType.asfDeviceId(username: username)
            let asfData = try? await credentialStoreClient.fetchData(type: dataType)
            if case .asfDeviceId(let deviceId, _) = asfData {
                return deviceId
            }
            let uuid = UUID().uuidString
            try await credentialStoreClient.storeData(data: .asfDeviceId(uuid, username))
            return uuid
        }

    static func encodedContext(username: String,
                               asfDeviceId: String,
                               asfClient: AdvancedSecurityBehavior,
                               userPoolConfiguration: UserPoolConfigurationData) -> String? {
        let deviceInfo: ASFDeviceBehavior = ASFDeviceInfo(id: asfDeviceId)
        let appInfo: ASFAppInfoBehavior = ASFAppInfo()

        do {
            return try asfClient.userContextData(
                for: username,
                deviceInfo: deviceInfo,
                appInfo: appInfo,
                configuration: userPoolConfiguration)
        } catch {
            // Ignore the error and add nil as context data
            return nil
        }
    }
}
