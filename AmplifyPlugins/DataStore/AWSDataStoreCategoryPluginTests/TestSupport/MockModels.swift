//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

}

extension MockSynced {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema(attributes: .isSyncable) { model in
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

}

extension MockUnsynced {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let post = MockUnsynced.keys

        model.fields(
            .id()
        )
    }

}
