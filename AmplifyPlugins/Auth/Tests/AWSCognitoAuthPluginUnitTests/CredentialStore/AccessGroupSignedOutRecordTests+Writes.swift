//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// How the access-group sign-out writes the signed-out record: in one update that writes only over a record still
/// there, never over one already signed out, and failing the sign-out when the write fails; and the keychain queries it
/// issues.
extension AccessGroupSignedOutRecordTests {

    /// Test that a sign-out completes when another process deletes the record while it is being replaced
    ///
    /// - Given: alice's login in the shared service, and the plugin configured with the access group over a keychain
    ///   whose `set` checks for the item, then updates it, as `KeychainItemStore.set` does outside native macOS; another
    ///   process in the group deletes the record between any such check and its update
    /// - When:
    ///    - the plugin signs out
    /// - Then:
    ///    - the sign-out completes, the user is signed out, and the record is the signed-out record: the replace is one
    ///      update, with no check before it
    ///
    func testASignOutCompletesWhenAnotherProcessDeletesTheRecordBeforeTheWrite() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        let keychain = keychain!
        let sessionAccount = sessionAccount
        let plugin = makePlugin(
            accessGroup: accessGroup,
            userPool: signOutUserPool(),
            makeKeychainStore: { service, accessGroup in
                CheckThenUpdateItemStore(base: keychain.store(service: service, accessGroup: accessGroup)) { key in
                    if key == sessionAccount {
                        try? keychain.store(service: service, accessGroup: accessGroup).remove(key)
                    }
                }
            }
        )

        let result = await plugin.signOut()

        guard let signOut = result as? AWSCognitoSignOutResult, case .complete = signOut else {
            return XCTFail("the sign-out did not complete: \(result)")
        }
        guard case .configured(.signedOut, _, _) = await plugin.authStateMachine.currentState else {
            return XCTFail("the sign-out ended in \(await plugin.authStateMachine.currentState)")
        }
        XCTAssertEqual(sharedRecord(), signedOutRecord)
    }

    /// Test that the store leaves the session signed out when another process deletes the record after the read
    ///
    /// - Given: alice's login in the shared service, and another process in the group that deletes the record right
    ///   after the store reads it
    /// - When:
    ///    - the store with the access group ends its session
    /// - Then:
    ///    - it does not throw, and writes no record: the session is already signed out
    ///
    func testTheStoreWritesNothingWhenTheRecordIsDeletedAfterTheRead() throws {
        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        let store = makeStore(accessGroup: accessGroup)
        let keychain = keychain!
        let sharedService = sharedService
        let accessGroup = accessGroup
        keychain.afterRead { service, account in
            keychain.afterRead(nil)
            try? keychain.store(service: sharedService, accessGroup: accessGroup).remove(account)
            XCTAssertEqual(service, sharedService)
        }

        try store.deleteCredential()

        XCTAssertNil(sharedRecord())
    }

    /// Test that the store writes nothing over a record that is already signed out
    ///
    /// - Given: the signed-out record in the shared service
    /// - When:
    ///    - the store with the access group ends its session
    /// - Then:
    ///    - the record is unchanged, and nothing was written or removed
    ///
    func testTheStoreWritesNothingOverASignedOutRecord() throws {
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(signedOutRecord, key: sessionAccount)
        let store = makeStore(accessGroup: accessGroup)
        keychain.resetMutations()

        try store.deleteCredential()

        XCTAssertEqual(sharedRecord(), signedOutRecord)
        XCTAssertEqual(keychain.mutations, [])
    }

    /// Test that a sign-out whose write of the signed-out record fails reports the failure and keeps the login
    ///
    /// - Given: alice's login in the shared service, the plugin configured with the access group, and a keychain that
    ///   refuses every write
    /// - When:
    ///    - the plugin signs out
    /// - Then:
    ///    - the sign-out fails, rather than completing with the login still saved, and the record still holds alice
    ///
    func testASignOutWhoseWriteFailsReportsTheFailure() async throws {
        let alice = try JSONEncoder().encode(LongLivedCredentials.userPoolAndIdentityPool())
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(alice, key: sessionAccount)
        let plugin = makePlugin(accessGroup: accessGroup, userPool: signOutUserPool())
        keychain.failing(.write, with: errSecInteractionNotAllowed)
        defer { keychain.clearFailures() }

        let result = await plugin.signOut()

        guard let signOut = result as? AWSCognitoSignOutResult, case .failed = signOut else {
            return XCTFail("the sign-out did not fail: \(result)")
        }
        XCTAssertEqual(sharedRecord(), alice)
    }

    /// Test the keychain queries a sign-out and a user deletion issue under an access group
    ///
    /// - Given: alice's login in the shared service, and the plugin configured with the access group over a keychain
    ///   that records every query
    /// - When:
    ///    - the plugin signs out; then, signed in again, deletes the user
    /// - Then:
    ///    - each reads the session record, then replaces it with the signed-out record in one update, in the shared
    ///      service and group, and deletes nothing there
    ///
    func testTheKeychainQueriesOfASignOutAndAUserDeletionUnderAnAccessGroup() async throws {
        let recorder = KeychainQueryRecorder(keychain: keychain)
        recorder.substitute(sessionAccount, with: "<session>")
        let sessionWrites = { () -> [String] in
            recorder.queries.filter { $0.contains("<session>") && $0.contains(" | \(self.sharedService) | ") }
        }
        let expected = [
            "store | getData | \(sharedService) | \(accessGroup) | <session> -> ok",
            "store | replaceIfPresent | \(sharedService) | \(accessGroup) | <session> -> true"
        ]

        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        let signingOut = makePlugin(
            accessGroup: accessGroup,
            userPool: signOutUserPool(),
            makeKeychainStore: recorder.makeKeychainStore
        )
        _ = try? await signingOut.getCurrentUser()
        recorder.reset()
        _ = await signingOut.signOut()
        XCTAssertEqual(Array(sessionWrites().suffix(2)), expected, "\(recorder.queries)")
        XCTAssertFalse(recorder.queries.contains { $0.contains(" | remove | \(sharedService) | ") && $0.contains("<session>") })

        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        let deleting = makePlugin(
            accessGroup: accessGroup,
            userPool: signOutUserPool(),
            makeKeychainStore: recorder.makeKeychainStore
        )
        _ = try? await deleting.getCurrentUser()
        recorder.reset()
        try await deleting.deleteUser()
        XCTAssertEqual(Array(sessionWrites().suffix(2)), expected, "\(recorder.queries)")
        XCTAssertFalse(recorder.queries.contains { $0.contains(" | remove | \(sharedService) | ") && $0.contains("<session>") })
        XCTAssertEqual(sharedRecord(), signedOutRecord)
    }
}

/// A store whose `set` is `KeychainItemStore.set` outside native macOS: a check for the item, then an update if it was
/// there (failing with `errSecItemNotFound` if it is gone by then) or an add. `betweenCheckAndUpdate` runs in between,
/// as another process's write would land. Every other call goes to `base`.
private struct CheckThenUpdateItemStore: KeychainItemStoreBehavior {
    let base: any KeychainItemStoreBehavior
    let betweenCheckAndUpdate: @Sendable (_ key: String) -> Void

    func set(_ value: Data, key: String) throws {
        let exists = try base.dataIfPresent(key) != nil
        betweenCheckAndUpdate(key)
        if exists {
            guard try base.replaceIfPresent(value, key: key) else {
                throw KeychainAccessError.securityError(errSecItemNotFound)
            }
        } else if try !base.addIfAbsent(value, key: key) {
            _ = try base.replaceIfPresent(value, key: key)
        }
    }

    func getData(_ key: String) throws -> Data { try base.getData(key) }
    func addIfAbsent(_ value: Data, key: String) throws -> Bool { try base.addIfAbsent(value, key: key) }
    func replaceIfPresent(_ value: Data, key: String) throws -> Bool { try base.replaceIfPresent(value, key: key) }
    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(key, to: destination)
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(entry, to: destination)
    }

    func remove(_ key: String) throws { try base.remove(key) }
    func remove(_ entry: KeychainEntry) throws { try base.remove(entry) }
    func removeAll() throws { try base.removeAll() }
    func hasItems() throws -> Bool { try base.hasItems() }
    func allAccounts() throws -> [String] { try base.allAccounts() }
    func allEntries() throws -> [KeychainEntry] { try base.allEntries() }
}
