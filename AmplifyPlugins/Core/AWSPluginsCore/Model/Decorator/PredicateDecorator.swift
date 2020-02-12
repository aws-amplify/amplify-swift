//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Decorates a GraphQL mutation with a "condition" input or a GraphQL query with a "filter" input. The value is the
/// data extracted from an instance of a `QueryPredicate`
public struct PredicateDecorator: ModelBasedGraphQLDocumentDecorator {

    private let predicate: QueryPredicate

    public init(predicate: QueryPredicate) {
        self.predicate = predicate
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs
        let modelName = modelType.schema.name
        if case .mutation = document.operationType {
            inputs["condition"] = GraphQLDocumentInput(type: "Model\(modelName)ConditionInput",
                value: .object(predicate.graphQLFilterVariables))
        } else if case .query = document.operationType {
            inputs["filter"] = GraphQLDocumentInput(type: "Model\(modelName)FilterInput",
                value: .object(predicate.graphQLFilterVariables))
        }

        return document.copy(inputs: inputs)
    }
}
