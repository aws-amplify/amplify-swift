//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// Revokes a stored session's tokens when no live session core holds it (`signOutStoredSession`), with the
/// same `revoke(payload, global: false)` a live session runs.
///
/// **Stateless, and it touches no keychain.** Its engine's device records are inert: every read is absent,
/// every write is dropped. A revoke never reads device records anyway; the inert store makes sure of it. Its
/// SDK clients are its own, built once from the configuration with no escape hatch, because there is no
/// client instance whose `configureUserPoolClient` would apply.
struct LiveSessionRevoker: SessionRevoker {

    private let engine: Result<LiveSessionEngine, Error>

    init(configuration: AuthClientConfiguration) {
        self.engine = Result {
            try LiveSessionEngine(resources: Self.resources(
                configuration: configuration,
                clients: CognitoServiceClients(configuration: configuration, configureUserPoolClient: nil)
            ))
        }
    }

    init(resources: EngineResources) {
        self.engine = .success(LiveSessionEngine(resources: resources))
    }

    /// A transient engine's resources: the configuration's clients, inert device records, and no analytics
    /// (its Pinpoint app is always `nil` today, and a revoke sends no analytics metadata anyway).
    ///
    /// - Parameter services: what the engine calls Cognito through; the clients' own unless a test scripts them.
    static func resources(
        configuration: AuthClientConfiguration,
        clients: CognitoServiceClients,
        services: EngineServices? = nil
    ) -> EngineResources {
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil)
        return EngineResources(
            authConfiguration: AuthConfiguration(client: configuration),
            clients: clients,
            devices: DeviceRecordIO(store: .inert(namespace: namespace)),
            analytics: LazyUserPoolAnalytics(pinpointAppId: nil),
            services: services
        )
    }

    func revoke(_ payload: Data) async throws -> EngineSignOutOutcome {
        try await engine.get().revoke(payload, global: false)
    }

    func signOutPresentsBrowser(_ payload: Data) -> Bool {
        (try? engine.get().signOutPresentsBrowser(payload)) ?? false
    }
}
