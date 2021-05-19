//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQLDocument with either a single id of `Model.Identifier`
/// or with all fields part of a custom primary key for a "delete" mutation
public struct ModelDeleteDecorator: ModelBasedGraphQLDocumentDecorator {

    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if case .mutation = document.operationType {
            var objectMap = [String: Any?]()
            if let customPrimaryKeys = modelSchema.customPrimaryIndexFields {
                for key in customPrimaryKeys {
                    objectMap[key] = model[key]
                }
            } else {
                objectMap["id"] = model.id
            }

            inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                   value: .object(objectMap))
        } else if case .query = document.operationType {
            inputs["id"] = GraphQLDocumentInput(type: "ID!", value: .scalar(model.id))
        }

        return document.copy(inputs: inputs)
    }
}
