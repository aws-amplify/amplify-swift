//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Dispatch
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth

/// The Pinpoint endpoint ID Cognito's user-pool analytics are keyed by, read lazily.
///
/// The plugin reads it in `UserPoolAnalytics.init`, through the legacy keychain factory, during configure.
/// The client reads it:
/// - **never**, when no Pinpoint app ID is configured (always, today): `analyticsMetadata()` is `nil`
///   and no keychain is touched;
/// - otherwise **once**, on first use and never in `init`, in the order `InternalAWSPinpoint`'s
///   `PinpointContext.retrieveUniqueId` uses, **reading only**:
///   1. the keychain: service `com.amazonaws.AWSPinpointContext` (no access group), account
///      `com.amazonaws.AWSPinpointContextKeychainUniqueIdKey`, as a UTF-8 string;
///   2. the legacy preferences file, `<Application Support>/com.amazonaws.MobileAnalytics/<pinpointAppId>/preferences`,
///      a JSON object whose `UniqueId` is the ID;
///   3. `UserDefaults`, under the same key as the keychain account.
///
///   The first ID found is used. If none is, no endpoint ID is sent.
///
/// **The client never writes the ID.** That storage belongs to the Pinpoint
/// Analytics and Push plugins: they look in the keychain first and only migrate (2) and (3) into it on a
/// miss, so an ID the client wrote there would be adopted in place of the app's real one, and their
/// migration skipped. The Auth plugin's writes miss that account only because its `_set` arguments are
/// swapped. So nothing here writes, moves or removes anything, in any of the three sources.
///
/// **A keychain failure is never "absent".** A failed keychain read does not fall through to (2) and (3),
/// which could hold an older ID than the keychain; the ID stays unresolved, that request goes without it,
/// and the next request tries again. A keychain value that is not a non-empty UTF-8 string does fall through, as Pinpoint's does.
/// "None found" is cached for this instance's lifetime; an ID Pinpoint creates later is picked up by the
/// next engine.
///
/// **Resolved on demand.** The engine's `analyticsMetadata()` is `async`, so the
/// first request that needs the ID waits for the lookup, and every later one reads the cached result. There
/// is no separate warm-up call. The engine reads this through `cognitoUserPoolAnalyticsHandlerFactory()` on
/// every request, so it must be handed **one instance per engine** (`EngineResources.analytics`), never a new
/// one per call, or every request would redo the lookup.
///
/// **No lock is held across I/O.** The lookup runs on this object's own queue through `runBlocking`, off the
/// cooperative pool, and its result is published under a short critical section. Concurrent first callers
/// share one lookup: the first starts it, the rest await the same task, so a stuck keychain call parks no
/// pool thread.
final class LazyUserPoolAnalytics: UserPoolAnalyticsBehavior, @unchecked Sendable {

    static let pinpointContextService = "com.amazonaws.AWSPinpointContext"
    static let endpointIdAccount = "com.amazonaws.AWSPinpointContextKeychainUniqueIdKey"
    static let legacyPreferencesRoot = "com.amazonaws.MobileAnalytics"
    static let legacyPreferencesFileName = "preferences"
    static let legacyPreferencesUniqueIdKey = "UniqueId"

    private enum State {
        case unresolved
        case resolving(Task<Void, Never>)
        case resolved(String?)
    }

    let pinpointAppId: String?
    private let keychain: any KeychainItemStoreBehavior
    private let userDefaults: UserDefaults
    private let applicationSupportDirectory: @Sendable () -> URL?
    private let queue: DispatchQueue

    // `@unchecked Sendable`: `state` is only touched while holding `lock`, and the lock is only ever held
    // for a read or an assignment of `state`, never across I/O or an `await`.
    private let lock = NSLock()
    private var state = State.unresolved

    /// Does no I/O: the three sources are only described here, and are first read by `analyticsMetadata()`. The
    /// defaults are the ones `PinpointContext` reads: the keychain service without an access group,
    /// `UserDefaults.standard`, and the user domain's Application Support directory.
    init(
        pinpointAppId: String?,
        keychain: any KeychainItemStoreBehavior = KeychainItemStore(
            service: LazyUserPoolAnalytics.pinpointContextService,
            logger: ClientLog.logger(ClientLog.keychainItemStore)
        ),
        userDefaults: UserDefaults = .standard,
        applicationSupportDirectory: @escaping @Sendable () -> URL? = {
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        },
        queue: DispatchQueue = DispatchQueue(label: "com.amazonaws.amplify.cognito-client.analytics-io")
    ) {
        self.pinpointAppId = pinpointAppId
        self.keychain = keychain
        self.userDefaults = userDefaults
        self.applicationSupportDirectory = applicationSupportDirectory
        self.queue = queue
    }

    /// Whether a Pinpoint app ID is configured. Without one, nothing here reads any of the sources.
    var isEnabled: Bool {
        pinpointAppId.map { !$0.isEmpty } ?? false
    }

    /// The analytics metadata for one user-pool request: the endpoint ID, or `nil` if there is none.
    ///
    /// Returns `nil` at once, with no I/O, when analytics are disabled. Otherwise the first call reads the
    /// sources (joining a lookup already in progress), and every later call returns the cached result. After a
    /// keychain failure it returns `nil`, and the next call retries.
    func analyticsMetadata() async -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType? {
        await resolvedEndpointId().map { .init(analyticsEndpointId: $0) }
    }

    /// The endpoint ID, resolving it first if needed; see `analyticsMetadata()`.
    ///
    /// **Before `pinpointAppId` can be set** (unreachable today, when it is always `nil`):
    /// a request awaits the lookup task, whose keychain read blocks a queue, and neither observes
    /// cancellation. So a stuck read would hold every user-pool request that needs the metadata, and
    /// cancelling the operation would not free it; after a keychain failure each later request reads again.
    /// Bound the wait then: race the lookup against a short timeout, or use `withTaskCancellationHandler`,
    /// and send the request without metadata when it loses.
    func resolvedEndpointId() async -> String? {
        guard isEnabled else {
            return nil
        }
        let lookup: Task<Void, Never>? = withLock {
            switch state {
            case .resolved:
                return nil
            case .resolving(let task):
                return task
            case .unresolved:
                let task = Task { await self.resolve() }
                state = .resolving(task)
                return task
            }
        }
        await lookup?.value
        return endpointId
    }

    /// The resolved endpoint ID, or `nil` if there is none or it is not resolved yet. No I/O.
    var endpointId: String? {
        withLock {
            guard case .resolved(let endpointId) = state else {
                return nil
            }
            return endpointId
        }
    }

    /// One lookup, without the lock. A keychain failure leaves the state unresolved, so a later call
    /// tries again.
    private func resolve() async {
        // Not `try?`: it would flatten a failure and a resolved "no ID" into the same `nil`.
        let next: State
        do {
            next = try await .resolved(runBlocking(on: queue) { [self] in try lookUp() })
        } catch {
            next = .unresolved
        }
        withLock { state = next }
    }

    private func withLock<Value>(_ body: () -> Value) -> Value {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    /// The existing ID from the first source that has one, or `nil` if none does. Reads only. Throws
    /// only for a keychain failure.
    private func lookUp() throws -> String? {
        if let stored = try keychain.dataIfPresent(Self.endpointIdAccount),
           let endpointId = String(data: stored, encoding: .utf8), !endpointId.isEmpty {
            return endpointId
        }
        if let endpointId = legacyPreferencesEndpointId(), !endpointId.isEmpty {
            return endpointId
        }
        if let endpointId = userDefaults.string(forKey: Self.endpointIdAccount), !endpointId.isEmpty {
            return endpointId
        }
        return nil
    }

    /// `UniqueId` from the legacy preferences file, as `PinpointContext.legacyUniqueId` reads it.
    private func legacyPreferencesEndpointId() -> String? {
        guard let pinpointAppId,
              let directory = applicationSupportDirectory(),
              let data = try? Data(contentsOf: Self.legacyPreferencesFile(in: directory, pinpointAppId: pinpointAppId)),
              let preferences = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return preferences[Self.legacyPreferencesUniqueIdKey]
    }

    static func legacyPreferencesFile(in applicationSupportDirectory: URL, pinpointAppId: String) -> URL {
        applicationSupportDirectory
            .appendingPathComponent(legacyPreferencesRoot)
            .appendingPathComponent(pinpointAppId)
            .appendingPathComponent(legacyPreferencesFileName)
    }
}
