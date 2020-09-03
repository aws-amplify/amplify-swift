//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Used as HubPayload for the `SyncQueriesStarted`
public struct SyncQueriesStartedEvent {
    /// list of model names
    public let models: [String]

    public init(models: [String]) {
        self.models = models
    }
}
