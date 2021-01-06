//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct PaginatedList<ModelType: Model>: Decodable {
    public let items: [MutationSync<ModelType>]
    public let nextToken: String?
    public let startedAt: Int?
}
