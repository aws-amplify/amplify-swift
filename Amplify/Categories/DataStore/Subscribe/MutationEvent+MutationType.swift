//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension MutationEvent {

    /// <#Description#>
    enum MutationType: String, Codable {
        case create
        case update
        case delete
    }
}

public extension MutationEvent.MutationType {

    /// <#Description#>
    var graphQLMutationType: GraphQLMutationType {
        switch self {
        case .create:
            return .create
        case .update:
            return .update
        case .delete:
            return .delete
        }
    }

    /// <#Description#>
    /// - Parameter graphQLMutationType: <#graphQLMutationType description#>
    init(graphQLMutationType: GraphQLMutationType) {
        switch graphQLMutationType {
        case .create:
            self = .create
        case .update:
            self = .update
        case .delete:
            self = .delete
        }
    }
}
