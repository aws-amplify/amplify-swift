//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Everything a session core, and the static session-management calls, are built from. `live` in the
/// app; tests inject their own registry, gate table, keychain, engine and bounds.
struct SessionCoreDependencies: Sendable {

    typealias Registry = SessionRegistry<SessionStorageNamespace, SessionFingerprint, SessionCore>

    /// The limits on internal waits. Nanoseconds, because `Duration` needs iOS 16 and the floor is 15.
    struct Bounds: Sendable {
        /// How long an operation waits for a restore before surfacing
        /// `storageUnavailable(.interrupted)`. The live value is a placeholder until measured on device.
        var restoreNanoseconds: UInt64

        static let live = Bounds(restoreNanoseconds: 5_000_000_000)
    }

    let registry: Registry
    let gates: SessionRecordGates
    let makeStore: @Sendable (SessionStorageNamespace) -> SessionRecordStore
    let makeClients: @Sendable (
        AuthClientConfiguration,
        AmplifyCognitoClientUserPoolConfigurationProvider?
    ) throws -> CognitoServiceClients
    let makeEngine: @Sendable (SessionEngineContext) throws -> any SessionEngine
    let makeRevoker: @Sendable (AuthClientConfiguration) -> any SessionRevoker

    /// Starts a new core's restore. Must only spawn work, never perform it: it runs inside the
    /// client's synchronous `init`, under the registry lock.
    let scheduleRestore: @Sendable (SessionCore) -> Void

    let bounds: Bounds
    let now: @Sendable () -> Date

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The system-sheet lock every session's hosted-UI flows take: the process-wide one in the app, a test's
    /// own in tests, so no test touches `SystemSheetLock.shared`.
    var sheetLock: SystemSheetLock = .shared
    #endif

    static let live = SessionCoreDependencies(
        registry: SessionCoreRegistry.shared,
        gates: .shared,
        makeStore: { SessionRecordStore(namespace: $0) },
        makeClients: { try CognitoServiceClients(configuration: $0, configureUserPoolClient: $1) },
        makeEngine: { LiveSessionEngine(context: $0) },
        makeRevoker: { LiveSessionRevoker(configuration: $0) },
        scheduleRestore: { core in
            Task { await core.warmRestore() }
        },
        bounds: .live,
        now: { Date() }
    )
}
