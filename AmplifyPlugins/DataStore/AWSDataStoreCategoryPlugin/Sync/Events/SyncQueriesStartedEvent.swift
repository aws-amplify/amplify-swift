//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Used as HubPayload for the `SyncQueriesStarted`
public struct SyncQueriesStartedEvent {
    public let models: [String] /// list of model names

    public init(models: [String]) {
        self.models = models
    }
}
