//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct MutationSyncMetadata: Model {
    public let id: Model.Identifier
    public var deleted: Bool
    public var lastChangedAt: Int
    public var version: Int
    
    public var modelId: String {
        id.components(separatedBy: "|").last ?? ""
    }
    public var modelName: String {
        id.components(separatedBy: "|").first ?? ""
    }
    
    public init(id: Model.Identifier, deleted: Bool, lastChangedAt: Int, version: Int) {
        self.id = id
        self.deleted = deleted
        self.lastChangedAt = lastChangedAt
        self.version = version
    }
    
    public init(modelId: Model.Identifier, modelName: String, deleted: Bool, lastChangedAt: Int, version: Int) {
        let id = Self.identifier(modelName: modelName, modelId: modelId)
        self.init(id: id, deleted: deleted, lastChangedAt: lastChangedAt, version: version)
    }
    
    public static func identifier(modelName: String, modelId: Model.Identifier) -> String {
        "\(modelName)|\(modelId)"
    }
}
