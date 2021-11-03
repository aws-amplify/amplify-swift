//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct MutationSyncMetadata: Model {
    /// Alias of MutationSyncMetadata's identifier, which has the format of `{modelName}|{modelId}`
    public typealias Identifier = String
    
    public let id: MutationSyncMetadata.Identifier
    public var deleted: Bool
    public var lastChangedAt: Int
    public var version: Int
    
    static let deliminator = "|"
    
    public var modelId: String {
        id.components(separatedBy: MutationSyncMetadata.deliminator).last ?? ""
    }
    public var modelName: String {
        id.components(separatedBy: MutationSyncMetadata.deliminator).first ?? ""
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
    
    public static func identifier(modelName: String, modelId: Model.Identifier) -> MutationSyncMetadata.Identifier {
        "\(modelName)\(deliminator)\(modelId)"
    }
}
