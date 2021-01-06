//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// MARK: - MockSynced

public struct MockSynced: Model {

    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }

    public enum CodingKeys: String, ModelKey {
        case id
    }

    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let post = MockSynced.keys

        model.fields(
            .id()
        )
    }

}

// MARK: - MockUnsynced

public struct MockUnsynced: Model {

    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }

    public enum CodingKeys: String, ModelKey {
        case id
    }

    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let post = MockUnsynced.keys
        model.attributes(.isSystem)
        model.fields(
            .id()
        )
    }

}

struct MockModelRegistration: AmplifyModelRegistration {

    func registerModels(registry: ModelRegistry.Type) {
        registry.register(modelType: MockSynced.self)
        registry.register(modelType: MockUnsynced.self)
    }

    let version: String = "1"

}
