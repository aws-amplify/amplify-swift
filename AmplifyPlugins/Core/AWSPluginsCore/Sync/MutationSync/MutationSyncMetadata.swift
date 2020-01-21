//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct MutationSyncMetadata: Model {

    public let id: Model.Identifier
    public var deleted: Bool
    public var lastChangedAt: Int
    public var version: Int
}
