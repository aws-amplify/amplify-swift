//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import InternalAmplifyKeychain

public struct KeychainStoreMigrator {
    let oldAttributes: KeychainStoreAttributes
    let newAttributes: KeychainStoreAttributes

    /// Creates the stores the migration reads, moves and clears through. Always
    /// `KeychainStore(service:accessGroup:)` outside tests; a seam so the migration can run over the
    /// in-memory fake.
    private let makeStore: @Sendable (_ service: String, _ accessGroup: String?) -> KeychainStore

    public init(oldService: String, newService: String, oldAccessGroup: String?, newAccessGroup: String?) {
        self.init(
            oldService: oldService,
            newService: newService,
            oldAccessGroup: oldAccessGroup,
            newAccessGroup: newAccessGroup,
            makeStore: { KeychainStore(service: $0, accessGroup: $1) }
        )
    }

    /// `package` so the auth plugin's credential store can pass its own test seam through.
    package init(
        oldService: String,
        newService: String,
        oldAccessGroup: String?,
        newAccessGroup: String?,
        makeStore: @escaping @Sendable (_ service: String, _ accessGroup: String?) -> KeychainStore
    ) {
        self.oldAttributes = KeychainStoreAttributes(service: oldService, accessGroup: oldAccessGroup)
        self.newAttributes = KeychainStoreAttributes(service: newService, accessGroup: newAccessGroup)
        self.makeStore = makeStore
    }

    public func migrate() throws {
        let migrator = KeychainItemMigrator(
            source: oldAttributes.itemAttributes,
            destination: newAttributes.itemAttributes,
            sourceStore: makeStore(oldAttributes.service, oldAttributes.accessGroup).backingStore,
            // Only asked whether it holds items, which has always been silent on failure.
            destinationStore: makeStore(newAttributes.service, newAttributes.accessGroup).quietBackingStore,
            logger: AmplifyLoggerBridge<KeychainStoreMigrator>()
        )
        try KeychainStoreError.mapping {
            try migrator.migrate(clearingDestinationWith: clearDestination)
        }
    }

    /// Clears the destination before the move. Called by `migrate()` only when the destination already
    /// holds items. Cleared through `KeychainStore`, as before.
    ///
    /// Spares the standalone clients' session records, which may share the destination service. If the
    /// destination cannot be listed nothing is removed, and any account that then collides stays in the
    /// source.
    func clearDestination() {
        try? makeStore(newAttributes.service, newAttributes.accessGroup).removeAllExceptSessionRecords()
    }
}

extension KeychainStoreMigrator: DefaultLogger { }
