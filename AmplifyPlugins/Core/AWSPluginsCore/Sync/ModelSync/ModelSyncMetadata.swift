//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct ModelSyncMetadata: Model {
    /// The id of the ModelSyncMetada record is the name of the model being synced
    public let id: String

    /// The timestamp (in Unix seconds) at which the last sync was started, as reported by the service
    public var lastSync: Int?

    public init(id: String,
                lastSync: Int?) {
        self.id = id
        self.lastSync = lastSync
    }
}
