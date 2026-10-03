//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

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
    /// Revokes a login `.default` deleted on a configuration change, with the previous configuration's region and app
    /// client ID: `RevokeToken` refuses a token from another app client. `LiveSessionRevoker(previous:)` in
    /// `live`; inert by default, so dependencies a test builds never reach Cognito.
    var makePreviousConfigurationRevoker: @Sendable (AuthConfiguration) -> any SessionRevoker = { _ in
        InertSessionRevoker()
    }

    /// Starts a new core's restore. Must only spawn work, never perform it: it runs inside the
    /// client's synchronous `init`, under the registry lock.
    let scheduleRestore: @Sendable (SessionCore) -> Void

    let bounds: Bounds
    let now: @Sendable () -> Date

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The system-sheet lock every session's hosted-UI flows take: the process-wide one in the app, a test's
    /// own in tests, so no test touches `SystemSheetLock.shared`.
    var sheetLock: SystemSheetLock = .shared

    /// A test seam inside a sign-out's logout-page lease body, given the session: runs once the body has stopped
    /// the session's passkey registrations, before it checks for an interrupt and shows the page. Does nothing in
    /// the app. A test holds the body here to interrupt it at that moment.
    var afterLogoutStop: @Sendable (SessionID) async -> Void = { _ in }
    #endif

    static let live: SessionCoreDependencies = {
        var live = SessionCoreDependencies(
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
        live.makePreviousConfigurationRevoker = { LiveSessionRevoker(previous: $0) }
        return live
    }()
}

/// A revoker that revokes nothing and reports success: the default of `makePreviousConfigurationRevoker` outside
/// `live`.
struct InertSessionRevoker: SessionRevoker {
    func revoke(_ payload: Data) async throws -> EngineSignOutOutcome {
        .complete
    }

    func signOutPresentsBrowser(_ payload: Data) -> Bool {
        false
    }
}
