//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A snapshot of the items from DataStore, the changes since last snapshot, and whether this model has
/// finished syncing and subscriptions are active
public struct DataStoreQuerySnapshot<M: Model> {

    /// All model instances from the local store
    public let items: [M]

    /// Indicates whether all sync queries for this model are complete, and subscriptions are active
    public let isSynced: Bool

    /// Latest changes since last snapshot
    public let itemsChanged: [MutationEvent]

    public init(items: [M], isSynced: Bool, itemsChanged: [MutationEvent]) {
        self.items = items
        self.isSynced = isSynced
        self.itemsChanged = itemsChanged
    }
}
