//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import Foundation
import XCTest

/// The base class for suites that create client sessions.
///
/// Mint every session ID through `makeSessionID(_:accessGroup:)`. `tearDown` then signs each one out
/// with `signOutStoredSession`, which revokes its refresh token, purges its row, and waits until the
/// registry holds no live session for any of them. Each test is therefore independent: its users are its
/// own (`makeFreshUser(on:_:)`, `makeSignInUser()`), deleted after its sessions. Hold clients in locals, not
/// in properties: a client the test case still holds keeps its session live and makes `tearDown` time out.
class ClientIntegrationTestCase: XCTestCase {

    private var createdSessions: [CreatedSession] = []
    private var freshUsers: [FreshUser] = []

    /// A unique session ID (`<tag>-<8 hex>`), cleaned up in `tearDown`. Pass the `pool` the session signs
    /// in to (nil is the main configuration, the default backend's), so its sign-out revokes against that
    /// pool.
    func makeSessionID(_ tag: String, pool: SandboxPool? = nil, accessGroup: String? = nil) throws -> SessionID {
        let sessionId = try IntegrationTestEnvironment.uniqueSessionID(tag)
        createdSessions.append(CreatedSession(sessionId: sessionId, accessGroup: accessGroup, pool: pool))
        return sessionId
    }

    /// A client over a new session on `pool` (nil is the main configuration), cleaned up in `tearDown`.
    /// Hold it in a local.
    func makeClient(
        _ tag: String,
        pool: SandboxPool? = nil,
        accessGroup: String? = nil,
        configureUserPoolClient: AmplifyCognitoClientUserPoolConfigurationProvider? = nil
    ) throws -> AmplifyCognitoClient {
        let configuration = try pool.map(IntegrationTestEnvironment.configuration) ?? IntegrationTestEnvironment.configuration()
        return try AmplifyCognitoClient(configuration: configuration, options: .init(
            sessionId: makeSessionID(tag, pool: pool, accessGroup: accessGroup),
            accessGroup: accessGroup,
            configureUserPoolClient: configureUserPoolClient
        ))
    }

    /// A fresh user signed up on `pool` (`SandboxSignUp`), deleted in `tearDown` after the test's
    /// sessions are signed out.
    func makeFreshUser(on pool: SandboxPool, _ options: SandboxSignUp.Options = .init()) async throws -> FreshUser {
        let user = try await SandboxSignUp.signUp(on: pool, options)
        freshUsers.append(user)
        return user
    }

    /// A fresh user on the main configuration's pool with a password and no MFA, as a `TestUser`, deleted
    /// in `tearDown`: the user a sign-in test signs in, never one another run could be using.
    func makeSignInUser() async throws -> TestUser {
        try await makeFreshUser(on: .standard).testUser
    }

    override func tearDown() async throws {
        let sessions = createdSessions
        let users = freshUsers
        createdSessions = []
        freshUsers = []
        var firstError: Error?
        if !sessions.isEmpty {
            do {
                try await SessionCleanup.cleanUp(sessions)
            } catch {
                firstError = error
            }
        }
        // After the sessions: a user's deletion must not race its own session's sign-out.
        for user in users {
            do {
                try await SandboxUserCleanup.delete(user)
            } catch {
                firstError = firstError ?? error
            }
        }
        try await super.tearDown()
        if let firstError {
            throw firstError
        }
    }
}

/// One session a test created, and the access group it was created in.
struct CreatedSession: Sendable {
    let sessionId: SessionID
    let accessGroup: String?
    /// The pool the session signs in to; nil is the main configuration.
    var pool: SandboxPool?
}

enum SessionCleanup {

    /// The bound on each teardown sign-out and purge: generous for the network, finite for a deadlock.
    static let cleanupTimeout: TimeInterval = 60

    /// Cleans up sessions that may belong to different pools: one `cleanUp(_:configuration:)` per pool,
    /// with that pool's configuration (the main one for `pool == nil`), in the order the pools first appear.
    /// Best effort across pools too; the first error is rethrown at the end.
    static func cleanUp(_ sessions: [CreatedSession]) async throws {
        var pools: [SandboxPool?] = []
        for session in sessions where !pools.contains(session.pool) {
            pools.append(session.pool)
        }
        var firstError: Error?
        for pool in pools {
            do {
                let configuration = try pool.map(IntegrationTestEnvironment.configuration)
                    ?? IntegrationTestEnvironment.configuration()
                try await cleanUp(sessions.filter { $0.pool == pool }, configuration: configuration)
            } catch {
                firstError = firstError ?? error
            }
        }
        if let firstError {
            throw firstError
        }
    }

    /// Signs each session out (revoking its refresh token), purges its row, then waits until none of
    /// them is live in the registry.
    ///
    /// Best effort: every session gets both calls and the wait always runs, whatever fails along the
    /// way. The first error is rethrown at the end.
    static func cleanUp(_ sessions: [CreatedSession], configuration: AuthClientConfiguration) async throws {
        var firstError: Error?
        func record(_ error: Error) {
            firstError = firstError ?? error
        }
        for session in sessions {
            // Bounded: a sign-out routed through a live core that deadlocked must fail the teardown, not hang
            // the run.
            do {
                _ = try await bounded(Self.cleanupTimeout, "signing session \(session.sessionId) out at teardown") {
                    try await AmplifyCognitoClient.signOutStoredSession(
                        sessionId: session.sessionId,
                        configuration: configuration,
                        accessGroup: session.accessGroup
                    )
                }
            } catch {
                record(error)
            }
            do {
                try await bounded(Self.cleanupTimeout, "purging session \(session.sessionId) at teardown") {
                    try await AmplifyCognitoClient.purgeStoredSession(
                        sessionId: session.sessionId,
                        configuration: configuration,
                        accessGroup: session.accessGroup
                    )
                }
            } catch {
                record(error)
            }
        }
        do {
            try await waitUntilReleased(sessions.map(\.sessionId))
        } catch {
            record(error)
        }
        if let firstError {
            throw firstError
        }
    }

    /// Waits until the registry holds no live session for any of `sessionIds`. The bound only stops a
    /// leaked handle from hanging the run; nothing asserts on how long the wait takes.
    static func waitUntilReleased(_ sessionIds: [SessionID], timeout: TimeInterval = 10) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while let live = sessionIds.first(where: { SessionCoreRegistry.shared.liveSession(for: $0) != nil }) {
            guard Date() < deadline else {
                throw HarnessError.timedOut("session \(live) to be released; is a client still held?")
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
