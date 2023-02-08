//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQL document with the data from an instance of the model. This is added as a single parameter
/// called "input" that can be referenced by other decorators to append additional document inputs. This decorator
/// constructs the input's type using the document name.
public struct ModelDecorator: ModelBasedGraphQLDocumentDecorator {

    private let model: Model
    private let mutationType: GraphQLMutationType
    private let changedFields: [String]?
    
    public init(model: Model, mutationType: GraphQLMutationType, changedFields: [String]? = nil) {
        self.model = model
        self.mutationType = mutationType
        self.changedFields = changedFields
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs
        // This takes a model instance and translates it to the GraphQL input.
        // This decorator is shared by the Model Helper APIs and the conflict resolution enabled Model Helpers
        //
        // The goal is to create a ModelDecorator which will produce a `graphqlInput` which only contains changed fields
        // What if we passed this decorator an additional `changedFields: [String]` which will be used to extract
        // only the changed fields from `graphQLInput`?
        var graphQLInput = model.graphQLInputForMutation(modelSchema, mutationType: mutationType)

        if !modelSchema.authRules.isEmpty {
            modelSchema.authRules.forEach { authRule in
                if authRule.allow == .owner {
                    let ownerField = authRule.getOwnerFieldOrDefault()
                    graphQLInput = graphQLInput.filter { (field, value) -> Bool in
                        if field == ownerField, value == nil {
                            return false
                        }
                        return true
                    }
                }
            }
        }
        if let changedFields = changedFields {
            // reduce `graphQLInput` to just the changed fields.
            // should always keep metadata fields like `version` and `updatedAt`.
        }

        inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
            value: .object(graphQLInput))
        return document.copy(inputs: inputs)
    }
}
