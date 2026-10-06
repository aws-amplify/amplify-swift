//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

extension TestKeychain {

    /// Records `configuration` as the Auth plugin's last configuration (`authConfiguration`), as the plugin, or a
    /// `.default` restore, leaves it: a `.default` restore under that configuration then changes nothing. Records no
    /// mutation.
    func recordPluginConfiguration(_ configuration: AuthClientConfiguration = ClientFixtures.configuration, accessGroup: String? = nil) {
        recordPluginConfiguration(AuthConfiguration(client: configuration), accessGroup: accessGroup)
    }

    /// `recordPluginConfiguration(_:accessGroup:)` for an engine configuration.
    func recordPluginConfiguration(_ configuration: AuthConfiguration, accessGroup: String? = nil) {
        do {
            try put(
                AWSCognitoAuthCredentialStore.encodeAuthConfiguration(configuration),
                SessionRecordStore.pluginConfigurationAccount,
                accessGroup: accessGroup
            )
        } catch {
            preconditionFailure("fixture encoding failed: \(error)")
        }
    }

    /// The Auth plugin's last configuration, as recorded, decoded.
    func recordedPluginConfiguration(accessGroup: String? = nil) -> AuthConfiguration? {
        value(SessionRecordStore.pluginConfigurationAccount, accessGroup: accessGroup)
            .flatMap { try? AWSCognitoAuthCredentialStore.decodeAuthConfiguration($0) }
    }
}
