//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
@testable import AmplifyFoundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Every line the client logs outside the engine is under an `AmplifyCognitoClient.<area>` category, so an
/// app's sink can tell it from the Auth plugin's lines and from any other library's.
final class ClientLogCategoryTests: XCTestCase {

    /// The categories the client's lines used before they had their own. None may appear again.
    private static let bareCategories = ["SessionRecordStore", "SessionSignOut", "KeychainItemStore"]

    private var keychain: TestKeychain!
    private var store: SessionRecordStore!
    private var sink: CategoryCapture!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        super.setUp()
        keychain = TestKeychain()
        store = keychain.recordStore(for: StorageFixtures.namespace)
        sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
    }

    override func tearDown() {
        AmplifyLogging.removeSink(sink)
        sink = nil
        super.tearDown()
    }

    private var markerAccount: String {
        SessionRecordKey.markerAccount(for: work, scope: TestKeychain.markerScope)
    }

    /// The categories are spelled out, not derived, so a rename shows here.
    ///
    /// - Given: the client's log areas
    /// - When: their categories are read
    /// - Then:
    ///    - each is `AmplifyCognitoClient.<area>`, and the challenge record's lines use the store's
    func testTheCategoryNames() {
        XCTAssertEqual(ClientLog.category(ClientLog.sessionRecordStore), "AmplifyCognitoClient.SessionRecordStore")
        XCTAssertEqual(ClientLog.category(ClientLog.sessionSignOut), "AmplifyCognitoClient.SessionSignOut")
        XCTAssertEqual(ClientLog.category(ClientLog.keychainItemStore), "AmplifyCognitoClient.KeychainItemStore")
        XCTAssertEqual(ClientLog.category(ClientLog.defaultSession), "AmplifyCognitoClient.DefaultSession")
        XCTAssertEqual(ClientLog.category(ClientLog.hostedUI), "AmplifyCognitoClient.HostedUI")
        XCTAssertEqual(SessionRecordStore.ChallengeLog.category, "AmplifyCognitoClient.SessionRecordStore")
        XCTAssertEqual((ClientLog.logger("X") as? ClientEngineLogger)?.name, "AmplifyCognitoClient.X")
    }

    /// Test that the session record store's warnings are under the client's category
    ///
    /// - Given: a capturing sink
    /// - When:
    ///    - each storage warning site is driven: listing an unrecognised plugin record, a namespace marker
    ///      whose write fails, a sign-out whose previous copies cannot be read, and a challenge sweep whose
    ///      delete fails
    /// - Then:
    ///    - each warning is logged under `AmplifyCognitoClient.SessionRecordStore`
    ///    - no line is logged under a bare `SessionRecordStore`, `SessionSignOut` or `KeychainItemStore`
    func testEveryStorageWarningIsUnderTheClientCategory() throws {
        // An unrecognised plugin record, listed.
        keychain.put(Data("not json".utf8), SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools))
        _ = try store.storedSessions()

        // A namespace marker whose write fails, at the record's creation.
        keychain.failingSets(of: markerAccount, with: errSecInteractionNotAllowed)
        _ = try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        keychain.clearFailures()

        // Previous copies that cannot be read, at sign-out.
        keychain.failingReads(of: markerAccount, with: errSecInteractionNotAllowed)
        _ = try? store.signOut(work)
        keychain.clearFailures()

        // An expired challenge record whose delete fails, at a listing's sweep.
        let createdAt = Date(timeIntervalSince1970: 1_790_000_000)
        try store.putChallenge(
            ChallengeRecord(createdAt: createdAt.addingTimeInterval(-16 * 60), state: .fake(.confirmSignInWithTOTPCode, session: "s")!),
            for: home
        )
        keychain.failingRemovals(of: store.challengeAccount(for: home), with: errSecInteractionNotAllowed)
        _ = try store.storedSessions(sweepingChallengesAt: createdAt)

        let category = ClientLog.category(ClientLog.sessionRecordStore)
        for fragment in [
            "The Auth plugin's session record has a shape this version does not recognise",
            "The session's namespace marker could not be written",
            "A session's copies under a previous configuration could not be read",
            SessionRecordStore.ChallengeLog.sweepFailed
        ] {
            XCTAssertEqual(sink.categories(containing: fragment), [category], fragment)
        }
        XCTAssertEqual(sink.lines(in: Self.bareCategories), [])
    }

    /// Test that the keychain item stores the client builds over the real keychain log under the client's category
    ///
    /// - Given: the session record store, the device record store and the Pinpoint analytics source, each over
    ///   the real keychain (inspected only, never read or written)
    /// - When: each one's `KeychainItemStore` logger is read
    /// - Then:
    ///    - it is the client's logger named `AmplifyCognitoClient.KeychainItemStore`
    func testTheRealKeychainStoresLogUnderTheClientCategory() throws {
        let namespace = SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: nil)
        let stores: [(String, Any)] = [
            ("SessionRecordStore", SessionRecordStore(namespace: namespace).keychain),
            ("DeviceRecordStore", try XCTUnwrap(Mirror(reflecting: DeviceRecordStore(namespace: namespace)).descendant("keychain"))),
            ("LazyUserPoolAnalytics", try XCTUnwrap(Mirror(reflecting: LazyUserPoolAnalytics(pinpointAppId: nil)).descendant("keychain")))
        ]
        for (owner, keychain) in stores {
            let itemStore = try XCTUnwrap(keychain as? KeychainItemStore, owner)
            let logger = try XCTUnwrap(Mirror(reflecting: itemStore).descendant("logger") as? ClientEngineLogger, owner)
            XCTAssertEqual(logger.name, "AmplifyCognitoClient.KeychainItemStore", owner)
        }
    }

    /// The client's logger redacts the query and fragment of every URL, at every level: the hosted UI's authorize
    /// URL that the engine's verbose line prints holds `state`, `nonce`, the PKCE challenge, `login_hint` and
    /// `userContextData`, and a redirect holds the authorization code.
    ///
    /// - Given: the engine's logger in the client, scoped as the hosted UI's actions are
    /// - When:
    ///    - an authorize URL and a redirect with a code are logged at each level, beside a line with no URL
    /// - Then:
    ///    - each line keeps the URL's scheme, host and path, and none of the query values reaches the sink
    ///    - the line with no URL is unchanged
    func testTheEngineLoggerRedactsURLQueries() throws {
        let scope = EngineLogScope.categoryNamespace("Authentication", "RedactionProbe-\(UUID().uuidString)")
        let logger = ClientEngineLogger().scoped(scope)
        let category = try XCTUnwrap(logger as? ClientEngineLogger).name
        let authorize = "https://app.auth.us-east-1.amazoncognito.com/oauth2/authorize?response_type=code"
            + "&client_id=client123&state=STATE-SECRET&nonce=NONCE-SECRET&code_challenge=CHALLENGE-SECRET"
            + "&login_hint=alice%40example.com&userContextData=CONTEXT-SECRET"
        let redirect = "myapp://callback/?code=CODE-SECRET&state=STATE-SECRET#FRAGMENT-SECRET"
        let message = "Showing url \(authorize) then Optional(\(redirect))"

        logger.error(message, nil)
        logger.warn(message, nil)
        logger.info(message, nil)
        logger.debug(message, nil)
        logger.verbose(message, nil)
        logger.log(.verbose, message, nil)
        logger.verbose("Starting execution", nil)

        let lines = sink.lines(in: [category])
        XCTAssertEqual(lines.count, 7)
        let expected = "Showing url https://app.auth.us-east-1.amazoncognito.com/oauth2/authorize?<redacted> then "
            + "Optional(myapp://callback/?<redacted>)"
        XCTAssertEqual(Array(lines.prefix(6)), Array(repeating: expected, count: 6))
        XCTAssertEqual(lines.last, "Starting execution")
        for line in lines {
            for secret in ["SECRET", "alice", "client123"] {
                XCTAssertFalse(line.contains(secret), line)
            }
        }
    }

    /// The client's logger also redacts the user identifiers the engine's verbose lines print in clear: `InitiateAuth`'s
    /// challenge parameters (`USERNAME`, `USER_ID_FOR_SRP`), a sign-in event's username, and the user's attributes, in
    /// each form the engine prints them. Everything else on the line is kept.
    ///
    /// - Given: the engine's logger in the client, scoped as the SRP step is
    /// - When:
    ///    - lines shaped as the engine prints its events, Cognito's challenge parameters and its state dumps are
    ///      logged, beside a line that mentions a username without a value
    /// - Then:
    ///    - every identifier's value is `<redacted>`, keeping its key and quoting, at every level
    ///    - the other parameters (`SALT`, the challenge name) and the line without a value are unchanged
    func testTheEngineLoggerRedactsUserIdentifiers() throws {
        let scope = EngineLogScope.categoryNamespace("Authentication", "IdentifierProbe-\(UUID().uuidString)")
        let logger = ClientEngineLogger().scoped(scope)
        let category = try XCTUnwrap(logger as? ClientEngineLogger).name
        let challenge = #"Sending event InitiateAuthOutput(ChallengeName: "PASSWORD_VERIFIER", ChallengeParameters: "#
            + #"["SALT": "79b0", "USERNAME": "royji2", "USER_ID_FOR_SRP": "royji2"])"#
        let respond = #"RespondToAuthChallenge(challenge: smsMfa, username: "alice", session: Optional("S"), "#
            + #"parameters: Optional(["userAttributes": "{\"email\":\"alice@example.com\"}"]), "#
            + #"inputUsername: Optional("alice@example.com"))"#
        let nested = #"tokens = "[\"username\": \"bob\", \"idToken\": \"ey*****re\"]"; userName = carol; "#
            + #"userId = "tr**ub"; deviceMetadata = "noData";"#
        let mention = "Unable to extract username from signInEventData"

        logger.verbose(challenge, nil)
        logger.debug(respond, nil)
        logger.info(nested, nil)
        logger.warn(challenge, nil)
        logger.error(respond, nil)
        logger.log(.verbose, nested, nil)
        logger.verbose(mention, nil)

        let lines = sink.lines(in: [category])
        XCTAssertEqual(lines.count, 7)
        let redactedChallenge = #"Sending event InitiateAuthOutput(ChallengeName: "PASSWORD_VERIFIER", ChallengeParameters: "#
            + #"["SALT": "79b0", "USERNAME": "<redacted>", "USER_ID_FOR_SRP": "<redacted>"])"#
        let redactedRespond = #"RespondToAuthChallenge(challenge: smsMfa, username: "<redacted>", session: Optional("S"), "#
            + #"parameters: Optional(["userAttributes": "<redacted>"]), inputUsername: Optional("<redacted>"))"#
        let redactedNested = #"tokens = "[\"username\": \"<redacted>\", \"idToken\": \"ey*****re\"]"; "#
            + #"userName = <redacted>; userId = "<redacted>"; deviceMetadata = "noData";"#
        XCTAssertEqual(lines, [
            redactedChallenge, redactedRespond, redactedNested, redactedChallenge, redactedRespond, redactedNested, mention
        ])
        for line in lines {
            for secret in ["royji2", "alice", "bob", "carol", "example.com", "tr**ub"] {
                XCTAssertFalse(line.contains(secret), line)
            }
        }
    }
}

/// Records the category (the logger name) of every line logged through `AmplifyLogging` while it is registered.
final class CategoryCapture: LogSinkBehavior, @unchecked Sendable {

    let id = UUID().uuidString

    // `@unchecked Sendable`: `messages` is only touched while holding `lock`.
    private let lock = NSLock()
    private var messages: [(name: String, content: String)] = []

    func isEnabled(for logLevel: LogLevel) -> Bool {
        true
    }

    func emit(message: LogMessage) {
        lock.withLock { messages.append((message.name, message.content)) }
    }

    /// The categories of the lines whose text contains `fragment`, in order, without repeats.
    func categories(containing fragment: String) -> [String] {
        lock.withLock {
            messages.filter { $0.content.contains(fragment) }.map(\.name).reduce(into: [String]()) { names, name in
                if !names.contains(name) { names.append(name) }
            }
        }
    }

    /// The lines logged under any of `categories`.
    func lines(in categories: [String]) -> [String] {
        lock.withLock { messages.filter { categories.contains($0.name) }.map(\.content) }
    }

}
