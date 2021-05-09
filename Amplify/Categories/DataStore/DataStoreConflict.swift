//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Information about a conflict that occurred attempting to sync a local model with a remote model
public struct DataStoreSyncConflict {

    /// <#Description#>
    public let localModel: Model

    /// <#Description#>
    public let remoteModel: Model

    /// <#Description#>
    public let errors: [GraphQLError]?

    /// <#Description#>
    public let mutationType: GraphQLMutationType
}
