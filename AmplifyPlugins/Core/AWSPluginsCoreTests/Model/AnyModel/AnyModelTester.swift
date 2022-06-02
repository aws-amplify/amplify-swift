//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct AnyModelTester: Model {
    let id: Identifier
    let stringProperty: String
    let intProperty: Int

    init(id: Identifier = "test-id", stringProperty: String, intProperty: Int) {
        self.id = id
        self.stringProperty = stringProperty
        self.intProperty = intProperty
    }
}

extension AnyModelTester {
    // MARK: - CodingKeys

    public enum CodingKeys: String, ModelKey {
        case id
        case stringProperty
        case intProperty
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { definition in
        let anyModel = AnyModelTester.keys

        definition.fields(
            .id(),
            .field(anyModel.stringProperty, is: .required, ofType: .string),
            .field(anyModel.intProperty, is: .required, ofType: .int)
        )
    }
}

extension AnyModelTester: Equatable { }

extension AnyModel: Equatable {
    public static func == (lhs: AnyModel, rhs: AnyModel) -> Bool {
        // swiftlint:disable force_try
        let lhsInstance = try! lhs.instance.toJSON()
        let rhsInstance = try! rhs.instance.toJSON()
        // swiftlint:enable force_try

        return lhs.id == rhs.id
            && lhs.modelName == rhs.modelName
            && lhsInstance == rhsInstance
    }
}
