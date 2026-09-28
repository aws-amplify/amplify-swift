//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import Security
import XCTest
@_spi(KeychainStore) import AWSPluginsCore
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The plugin's read-only fallback to the Cognito client's default-session record,
/// `amplify.1.<pool namespace>.$default.session`, at the level of the credential store.
///
/// Runs over the in-memory keychain fake, shared with the client's real record store, so the records read
/// here are written by the client's own code.
class AWSCognitoAuthCredentialStoreDefaultSessionRecordTests: XCTestCase {

    private let userPool = UserPoolConfigurationData(poolId: "us-east-1_Pool", clientId: "client", region: "us-east-1")
    private let otherUserPool = UserPoolConfigurationData(poolId: "us-east-1_Other", clientId: "client", region: "us-east-1")
    private let identityPool = IdentityPoolConfigurationData(poolId: "us-east-1:identity-pool", region: "us-east-1")

    private var authConfiguration: AuthConfiguration {
        .userPoolsAndIdentityPools(userPool, identityPool)
    }

    private let legacyAccount = "amplify.us-east-1_Pool.us-east-1:identity-pool.session"
    private let clientAccount = "amplify.1.us-east-1_Pool.us-east-1:identity-pool.$default.session"
    private let signedOutBytes = Data(#"{"noCredentials":{}}"#.utf8)

    private var keychain: InMemoryKeychain!
    private var pluginKeychain: InMemoryPluginKeychainStore!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
        pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
    }

    override func tearDown() {
        keychain = nil
        pluginKeychain = nil
        super.tearDown()
    }

    // MARK: - The key

    /// Test that the plugin looks for the client's default session under the client's exact key
    ///
    /// - Given: A credential store for each kind of auth configuration
    /// - When:
    ///    - The default-session record key is generated
    /// - Then:
    ///    - It is `amplify.1.<pool ids>.$default.session`, character for character, and it is the key the
    ///      client's own key renderer produces for its default session
    ///
    func testDefaultSessionRecordKey_isTheClientsKey() {
        let expectations: [(AuthConfiguration, String)] = [
            (.userPools(userPool), "amplify.1.us-east-1_Pool.$default.session"),
            (.identityPools(identityPool), "amplify.1.us-east-1:identity-pool.$default.session"),
            (authConfiguration, clientAccount)
        ]
        for (configuration, expected) in expectations {
            let store = makeStore(configuration)
            XCTAssertEqual(store.generateDefaultSessionRecordKey(for: configuration), expected)
            XCTAssertEqual(CognitoClientRecords.defaultSessionAccount(for: configuration), expected)
        }
    }

    // MARK: - Read precedence

    /// Test that a record written by the client is read when the plugin has none
    ///
    /// - Given: A keychain holding only the client's default-session record, written by the client's store
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - It gets exactly the credentials the client stored, and the client's record is byte-identical
    ///
    func testRetrieve_withOnlyAClientRecord_returnsItsCredentials() throws {
        let credentials = LongLivedCredentials.userPoolAndIdentityPool()
        let written = try CognitoClientRecords.writeDefaultSession(credentials, in: keychain, for: authConfiguration)
        let store = makeStore(authConfiguration)
        keychain.resetMutations()

        XCTAssertEqual(try store.retrieveCredential(), credentials)
        XCTAssertEqual(try CognitoClientRecords.storedBytes(in: keychain, for: authConfiguration), written)
        XCTAssertEqual(keychain.mutations, [])
    }

    /// Test that every kind of session the client can store is read back
    ///
    /// - Given: A client default-session record for each signed-in credential shape
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - It gets the stored credentials each time
    ///
    func testRetrieve_withEachSignedInShape_returnsItsCredentials() throws {
        let shapes: [AmplifyCredentials] = [
            .userPoolOnly(signedInData: SignedInData(
                signedInDate: Date(),
                signInMethod: .apiBased(.userSRP),
                cognitoUserPoolTokens: LongLivedCredentials.tokens()
            )),
            LongLivedCredentials.userPoolAndIdentityPool(),
            .identityPoolOnly(identityID: "guest-id", credentials: LongLivedCredentials.awsCredentials()),
            .identityPoolWithFederation(
                federatedToken: FederatedToken(token: "token", provider: .facebook),
                identityID: "federated-id",
                credentials: LongLivedCredentials.awsCredentials()
            )
        ]
        for credentials in shapes {
            let keychain = InMemoryKeychain()
            try CognitoClientRecords.writeDefaultSession(credentials, in: keychain, for: authConfiguration)
            let store = AWSCognitoAuthCredentialStore(
                authConfiguration: authConfiguration,
                keychain: InMemoryPluginKeychainStore(keychain: keychain)
            )
            XCTAssertEqual(try store.retrieveCredential(), credentials)
        }
    }

    /// Test that the plugin's own record wins over the client's
    ///
    /// - Given: The plugin's record for one user and the client's default-session record for another
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - It gets its own record, and never reads the client's
    ///
    func testRetrieve_withBothRecords_returnsThePluginsOwnAndNeverReadsTheClients() throws {
        try CognitoClientRecords.writeDefaultSession(
            LongLivedCredentials.userPoolAndIdentityPool(username: "bob"),
            in: keychain,
            for: authConfiguration
        )
        let pluginCredentials = LongLivedCredentials.userPoolAndIdentityPool(username: "alice")
        let store = makeStore(authConfiguration)
        try store.saveCredential(pluginCredentials)

        XCTAssertEqual(try store.retrieveCredential(), pluginCredentials)
        XCTAssertFalse(pluginKeychain.readAccounts.contains(clientAccount))
    }

    /// Test that a plugin record that cannot be decoded still wins
    ///
    /// - Given: Bytes under the plugin's key that are not credentials, and a readable client record
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - The decoding error is thrown as before, and the client's record is never read
    ///
    func testRetrieve_withAnUndecodablePluginRecord_throwsAndNeverReadsTheClients() throws {
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: authConfiguration)
        let store = makeStore(authConfiguration)
        try pluginKeychain.set(Data("not credentials".utf8), key: legacyAccount)

        XCTAssertThrowsError(try store.retrieveCredential()) { error in
            guard case EngineCredentialStoreError.codingError = error else {
                return XCTFail("Expected a coding error, got \(error)")
            }
        }
        XCTAssertFalse(pluginKeychain.readAccounts.contains(clientAccount))
    }

    /// Test that a failure reading the plugin's record is never answered from the client's
    ///
    /// - Given: A plugin record whose read fails because the device is locked, and a readable client record
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - The keychain error is thrown unchanged, and the client's record is never read
    ///
    func testRetrieve_whenThePluginRecordIsLocked_throwsAndNeverReadsTheClients() throws {
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: authConfiguration)
        let store = makeStore(authConfiguration)
        try store.saveCredential(LongLivedCredentials.userPoolAndIdentityPool(username: "alice"))
        pluginKeychain.failReads(of: legacyAccount, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store.retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .securityError(errSecInteractionNotAllowed))
        }
        XCTAssertFalse(pluginKeychain.readAccounts.contains(clientAccount))
    }

    /// Test that a failure reading the client's record is never reported as "no session"
    ///
    /// - Given: No plugin record, and a client record whose read fails because the device is locked
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - The keychain error is thrown, not `itemNotFound`
    ///
    func testRetrieve_whenTheClientRecordIsLocked_throwsTheKeychainError() throws {
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: authConfiguration)
        let store = makeStore(authConfiguration)
        pluginKeychain.failReads(of: clientAccount, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store.retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .securityError(errSecInteractionNotAllowed))
        }
    }

    /// Test that with neither record the result is exactly what it always was
    ///
    /// - Given: An empty keychain
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - It throws `itemNotFound`
    ///
    func testRetrieve_withNoRecords_throwsItemNotFound() {
        XCTAssertThrowsError(try makeStore(authConfiguration).retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
    }

    /// Test that another configuration's client record is never read
    ///
    /// - Given: A client default-session record for a different user pool
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - It throws `itemNotFound`
    ///
    func testRetrieve_withOnlyAnotherNamespacesClientRecord_throwsItemNotFound() throws {
        let otherConfiguration = AuthConfiguration.userPoolsAndIdentityPools(otherUserPool, identityPool)
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: otherConfiguration)

        XCTAssertThrowsError(try makeStore(authConfiguration).retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
    }

    // MARK: - Tolerance

    /// Test that an envelope carrying keys this release does not know still decodes
    ///
    /// - Given: A hand-written version-1 envelope with three extra keys (a boolean, a string and a nested
    ///   object) that the client's own decoder also accepts as a version-1 record
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - It gets the credentials in the envelope
    ///
    func testRetrieve_withThreeUnknownFields_stillDecodes() throws {
        let credentials = LongLivedCredentials.userPoolAndIdentityPool()
        let payload = try JSONEncoder().encode(credentials).base64EncodedString()
        let envelope = Data("""
        {"adoptedFromPluginRecord":true,"credentials":"\(payload)","deviceName":"Alice's iPad",\
        "futureObject":{"nested":[1,2,3],"flag":null},"generation":7,"kind":"userPoolAndIdentityPool",\
        "label":"Work","lastWriteTimestamp":1790000000123,"schemaVersion":1,"username":"alice"}
        """.utf8)
        guard case .envelope = SessionRecordEnvelope.decode(envelope) else {
            return XCTFail("The client should read this fixture as a version-1 record")
        }
        try pluginKeychain.set(envelope, key: clientAccount)

        XCTAssertEqual(try makeStore(authConfiguration).retrieveCredential(), credentials)
    }

    /// Test that a record from a schema version this release does not know is ignored, not misread
    ///
    /// - Given: Under the client's default-session key, in turn, a version-2 record whose fields no longer
    ///   have their version-1 shapes, and a version-2 record whose fields all still look like version 1
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - Each throws `itemNotFound`, as if there were no record, and the record is untouched
    ///
    func testRetrieve_withAnUnknownSchemaVersion_ignoresTheRecord() throws {
        let payload = try JSONEncoder().encode(LongLivedCredentials.userPoolAndIdentityPool()).base64EncodedString()
        let envelopes = [
            Data("""
            {"credentials":{"encrypted":"\(payload)"},"generation":1,"kind":{"signedIn":"userPool"},\
            "lastWriteTimestamp":1790000000123,"schemaVersion":2}
            """.utf8),
            Data("""
            {"credentials":"\(payload)","generation":1,"kind":"userPoolAndIdentityPool",\
            "lastWriteTimestamp":1790000000123,"schemaVersion":2}
            """.utf8)
        ]
        for envelope in envelopes {
            XCTAssertEqual(SessionRecordEnvelope.decode(envelope), .unsupportedSchema(version: 2))
            try pluginKeychain.set(envelope, key: clientAccount)
            keychain.resetMutations()

            XCTAssertThrowsError(try makeStore(authConfiguration).retrieveCredential()) { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), envelope)
            XCTAssertEqual(keychain.mutatedClientAccounts, [])
        }
    }

    /// Test that a record signed out by the client reads as no session
    ///
    /// - Given: A client default-session record the client then signed out, keeping the row
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - It throws `itemNotFound`
    ///
    func testRetrieve_withARecordTheClientSignedOut_throwsItemNotFound() throws {
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: authConfiguration)
        try CognitoClientRecords.signOutDefaultSession(in: keychain, for: authConfiguration)
        XCTAssertNotNil(keychain.value(service: pluginKeychainService, account: clientAccount), "The row should be kept")

        XCTAssertThrowsError(try makeStore(authConfiguration).retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
    }

    /// Test that records this reader cannot interpret are all ignored rather than misread
    ///
    /// - Given: Under the client's default-session key, in turn: bytes that are not JSON, no schema version,
    ///   schema version 0, no generation, a negative generation, no write timestamp, no kind, a kind
    ///   version 1 does not define, a signed-out kind that still holds credentials, a signed-in kind with
    ///   no credentials, credentials that are not base64, and base64 that is not credentials. Every record
    ///   but the one under test is otherwise valid, with a real credentials payload.
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - Each throws `itemNotFound`, and no record is written or deleted
    ///
    func testRetrieve_withUninterpretableRecords_ignoresEach() throws {
        let credentials = LongLivedCredentials.userPoolAndIdentityPool()
        let payload = try JSONEncoder().encode(credentials).base64EncodedString()
        let notCredentials = Data("{}".utf8).base64EncodedString()
        let stamp = #""generation":1,"lastWriteTimestamp":1790000000123"#
        let records = [
            "not json",
            #"{\#(stamp),"kind":"userPoolOnly","credentials":"\#(payload)"}"#,
            #"{"schemaVersion":0,\#(stamp),"kind":"userPoolOnly","credentials":"\#(payload)"}"#,
            #"{"schemaVersion":1,"lastWriteTimestamp":1790000000123,"kind":"userPoolOnly","credentials":"\#(payload)"}"#,
            #"{"schemaVersion":1,"generation":-1,"lastWriteTimestamp":1790000000123,"kind":"userPoolOnly","credentials":"\#(payload)"}"#,
            #"{"schemaVersion":1,"generation":1,"kind":"userPoolOnly","credentials":"\#(payload)"}"#,
            #"{"schemaVersion":1,\#(stamp),"credentials":"\#(payload)"}"#,
            #"{"schemaVersion":1,\#(stamp),"kind":"revoked","credentials":"\#(payload)"}"#,
            #"{"schemaVersion":1,\#(stamp),"kind":"none","credentials":"\#(payload)"}"#,
            #"{"schemaVersion":1,\#(stamp),"kind":"userPoolOnly"}"#,
            #"{"schemaVersion":1,\#(stamp),"kind":"userPoolOnly","credentials":"%%%"}"#,
            #"{"schemaVersion":1,\#(stamp),"kind":"userPoolOnly","credentials":"\#(notCredentials)"}"#
        ]
        let control = #"{"schemaVersion":1,\#(stamp),"kind":"userPoolAndIdentityPool","credentials":"\#(payload)"}"#
        try pluginKeychain.set(Data(control.utf8), key: clientAccount)
        XCTAssertEqual(
            try makeStore(authConfiguration).retrieveCredential(),
            credentials,
            "The control record, which each case below breaks in one way, should be readable"
        )
        for record in records {
            try pluginKeychain.set(Data(record.utf8), key: clientAccount)
            keychain.resetMutations()
            XCTAssertThrowsError(try makeStore(authConfiguration).retrieveCredential(), record) { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound, record)
            }
            XCTAssertEqual(keychain.mutatedClientAccounts, [], record)
        }
    }

    /// Test that the shapes this reader now rejects are ones the client's own decoder rejects too
    ///
    /// - Given: A record with no generation, one with no write timestamp, and a signed-out kind that still
    ///   holds credentials
    /// - When:
    ///    - The client's own envelope decoder classifies each
    /// - Then:
    ///    - It calls the first two corrupt, and does not call the third a signed-out row, so the plugin, which
    ///      ignores all three, never signs in from a record the client would not
    ///
    func testRejectedShapes_matchTheClientsDecoder() throws {
        let payload = try JSONEncoder().encode(LongLivedCredentials.userPoolAndIdentityPool()).base64EncodedString()
        let noGeneration = #"{"schemaVersion":1,"lastWriteTimestamp":1790000000123,"kind":"userPoolOnly","credentials":"\#(payload)"}"#
        let noTimestamp = #"{"schemaVersion":1,"generation":1,"kind":"userPoolOnly","credentials":"\#(payload)"}"#
        let signedOutWithCredentials =
            #"{"schemaVersion":1,"generation":1,"lastWriteTimestamp":1790000000123,"kind":"none","credentials":"\#(payload)"}"#

        XCTAssertEqual(SessionRecordEnvelope.decode(Data(noGeneration.utf8)), .corrupt)
        XCTAssertEqual(SessionRecordEnvelope.decode(Data(noTimestamp.utf8)), .corrupt)
        guard case .envelope(let envelope) = SessionRecordEnvelope.decode(Data(signedOutWithCredentials.utf8)) else {
            return XCTFail("The client decodes this shape")
        }
        XCTAssertFalse(envelope.record.isSignedOut)

        for shape in [noGeneration, noTimestamp, signedOutWithCredentials] {
            guard case .unreadable = DefaultSessionRecordReader.decode(Data(shape.utf8)) else {
                return XCTFail("The plugin should call this unreadable, not signed in or signed out: \(shape)")
            }
        }
    }

    // MARK: - Sign-out

    /// Test that deleting the credentials while a client record exists cannot bring the user back
    ///
    /// - Given: A session the plugin read from the client's record and then refreshed into its own record
    /// - When:
    ///    - The plugin deletes its credentials, as sign-out does
    /// - Then:
    ///    - Its own record holds `.noCredentials` in its existing format, the client's record is untouched,
    ///      and a later read, by this store or a new one, finds no session
    ///
    func testDelete_withAClientRecord_leavesASignedOutRecordAndTheClientsUntouched() throws {
        let written = try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: authConfiguration)
        let store = makeStore(authConfiguration)
        try store.saveCredential(store.retrieveCredential())

        try store.deleteCredential()

        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: legacyAccount), signedOutBytes)
        XCTAssertEqual(try CognitoClientRecords.storedBytes(in: keychain, for: authConfiguration), written)
        XCTAssertEqual(try store.retrieveCredential(), .noCredentials)
        XCTAssertEqual(try makeStore(authConfiguration).retrieveCredential(), .noCredentials)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    /// Test that deleting the credentials without a client record is exactly what it always was
    ///
    /// - Given: The plugin's own record and no client record
    /// - When:
    ///    - The plugin deletes its credentials
    /// - Then:
    ///    - Its record is removed, and nothing is written in its place
    ///
    func testDelete_withoutAClientRecord_removesTheRecordAsBefore() throws {
        let store = makeStore(authConfiguration)
        try store.saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        keychain.resetMutations()

        try store.deleteCredential()

        XCTAssertNil(keychain.value(service: pluginKeychainService, account: legacyAccount))
        XCTAssertEqual(keychain.mutations, [.remove(service: pluginKeychainService, account: legacyAccount)])
    }

    /// Test that deleting the credentials when the client record cannot be checked still cannot bring
    /// the user back
    ///
    /// - Given: A client record whose read fails
    /// - When:
    ///    - The plugin deletes its credentials
    /// - Then:
    ///    - Its own record holds `.noCredentials`, and the client's record is untouched
    ///
    func testDelete_whenTheClientRecordCannotBeRead_leavesASignedOutRecord() throws {
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: authConfiguration)
        let store = makeStore(authConfiguration)
        pluginKeychain.failReads(of: clientAccount, with: errSecInteractionNotAllowed)

        try store.deleteCredential()

        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: legacyAccount), signedOutBytes)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    /// Test that a failed write of the signed-out record still removes the live record
    ///
    /// - Given: The plugin's live record, a client record, and a keychain that refuses writes; in turn with
    ///   the client record readable and with its read failing
    /// - When:
    ///    - The plugin deletes its credentials
    /// - Then:
    ///    - The write error is thrown, the plugin's live record is deleted anyway, and the client's record is
    ///      untouched
    ///
    func testDelete_whenTheSignedOutRecordCannotBeWritten_removesTheRecordAndThrows() throws {
        for clientRecordReadFails in [false, true] {
            let keychain = InMemoryKeychain()
            let pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
            let written = try CognitoClientRecords.writeDefaultSession(
                LongLivedCredentials.userPoolAndIdentityPool(username: "bob"),
                in: keychain,
                for: authConfiguration
            )
            let store = AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration, keychain: pluginKeychain)
            try store.saveCredential(LongLivedCredentials.userPoolAndIdentityPool(username: "alice"))
            if clientRecordReadFails {
                pluginKeychain.failReads(of: clientAccount, with: errSecInteractionNotAllowed)
            }
            keychain.failing(.write, with: errSecInteractionNotAllowed)

            XCTAssertThrowsError(try store.deleteCredential(), "\(clientRecordReadFails)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .securityError(errSecInteractionNotAllowed))
            }

            XCTAssertNil(keychain.value(service: pluginKeychainService, account: legacyAccount), "\(clientRecordReadFails)")
            XCTAssertEqual(try CognitoClientRecords.storedBytes(in: keychain, for: authConfiguration), written)
            XCTAssertEqual(keychain.mutatedClientAccounts, [])
        }
    }

    /// Test that signing in again after such a sign-out replaces the signed-out record
    ///
    /// - Given: A signed-out plugin record left in front of a client record
    /// - When:
    ///    - The plugin saves a new session
    /// - Then:
    ///    - The new session is read back
    ///
    func testSave_afterASignedOutRecord_readsTheNewSession() throws {
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(username: "bob"), in: keychain, for: authConfiguration)
        let store = makeStore(authConfiguration)
        try store.deleteCredential()
        let credentials = LongLivedCredentials.userPoolAndIdentityPool(username: "alice")

        try store.saveCredential(credentials)

        XCTAssertEqual(try store.retrieveCredential(), credentials)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    // MARK: - Configuration changes

    /// Test that an unsupported configuration change does not leave the old configuration's client record
    /// able to sign its user back in
    ///
    /// - Given: A session under configuration A, read by the plugin from the client's record and refreshed
    ///   into its own
    /// - When:
    ///    - The app is configured with configuration B, whose user pool differs, which clears A's session,
    ///      and is later configured with A again
    /// - Then:
    ///    - Under A there is no session, and A's client record is byte-identical and was never written
    ///
    func testUnsupportedConfigurationChange_withAClientRecord_doesNotLeaveItToSignTheUserBackIn() throws {
        let written = try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: authConfiguration)
        let storeA = makeStore(authConfiguration)
        try storeA.saveCredential(storeA.retrieveCredential())

        _ = makeStore(.userPoolsAndIdentityPools(otherUserPool, identityPool))
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: legacyAccount), signedOutBytes)

        XCTAssertEqual(try makeStore(authConfiguration).retrieveCredential(), .noCredentials)
        XCTAssertEqual(try CognitoClientRecords.storedBytes(in: keychain, for: authConfiguration), written)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    /// Test that an unsupported configuration change without a client record is exactly what it was
    ///
    /// - Given: A plugin session under configuration A and no client record
    /// - When:
    ///    - The app is configured with configuration B, whose user pool differs
    /// - Then:
    ///    - A's record is removed
    ///
    func testUnsupportedConfigurationChange_withoutAClientRecord_removesTheOldRecordAsBefore() throws {
        try makeStore(authConfiguration).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())

        _ = makeStore(.userPoolsAndIdentityPools(otherUserPool, identityPool))

        XCTAssertNil(keychain.value(service: pluginKeychainService, account: legacyAccount))
    }

    /// Test that a supported configuration change still copies the plugin's own record, and only that
    ///
    /// - Given: Under an identity-pool-only configuration, the plugin's guest record and a client record
    /// - When:
    ///    - The app adds a user pool, keeping the identity pool
    /// - Then:
    ///    - The plugin's record is copied to the new namespace as before, and nothing is written to either
    ///      namespace's client key
    ///
    func testSupportedConfigurationChange_copiesOnlyThePluginsRecord() throws {
        let identityOnly = AuthConfiguration.identityPools(identityPool)
        let guest = AmplifyCredentials.identityPoolOnly(identityID: "guest", credentials: LongLivedCredentials.awsCredentials())
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: identityOnly)
        try makeStore(identityOnly).saveCredential(guest)
        keychain.resetMutations()

        let store = makeStore(authConfiguration)

        XCTAssertEqual(try store.retrieveCredential(), guest)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    /// Test that a supported configuration change does not turn a client record into a plugin record
    ///
    /// - Given: Under an identity-pool-only configuration, only a client record
    /// - When:
    ///    - The app adds a user pool, keeping the identity pool
    /// - Then:
    ///    - Nothing is copied: the new namespace has no session, and no plugin or client record is written
    ///      there
    ///
    func testSupportedConfigurationChange_withOnlyAClientRecord_copiesNothing() throws {
        let identityOnly = AuthConfiguration.identityPools(identityPool)
        try CognitoClientRecords.writeDefaultSession(LongLivedCredentials.userPoolAndIdentityPool(), in: keychain, for: identityOnly)
        _ = makeStore(identityOnly)
        keychain.resetMutations()

        let store = makeStore(authConfiguration)

        XCTAssertThrowsError(try store.retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
        XCTAssertFalse(keychain.mutatedAccounts.contains(legacyAccount))
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    // MARK: - Helpers

    private func makeStore(_ configuration: AuthConfiguration) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(authConfiguration: configuration, keychain: pluginKeychain)
    }
}
