//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension MutationEvent {
    // Explicit `Sendable`: Swift does not infer it for public types.
    enum MutationType: String, Codable, Sendable {
        case create
        case update
        case delete
    }
}

public extension MutationEvent.MutationType {
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
