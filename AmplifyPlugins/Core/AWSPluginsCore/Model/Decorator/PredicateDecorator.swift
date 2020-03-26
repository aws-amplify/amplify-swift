//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum QueryPredicateInput {
    case object(QueryPredicate)
    case json([String: Any])
}

/// Decorates a GraphQL mutation with a "condition" input or a GraphQL query with a "filter" input. The value is the
/// data extracted from an instance of a `QueryPredicate`
public struct PredicateDecorator: ModelBasedGraphQLDocumentDecorator {

    private let predicateInput: QueryPredicateInput

    public init(predicateInput: QueryPredicateInput) {
        self.predicateInput = predicateInput
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs
        let modelName = modelType.schema.name
        let predicateJSON: [String: Any]
        switch predicateInput {
        case .object(let queryPredicate):
            predicateJSON = queryPredicate.graphQLFilterVariables
        case .json(let json):
            predicateJSON = json
        }
        if case .mutation = document.operationType {
            inputs["condition"] = GraphQLDocumentInput(type: "Model\(modelName)ConditionInput",
                value: .object(predicateJSON))
        } else if case .query = document.operationType {
            inputs["filter"] = GraphQLDocumentInput(type: "Model\(modelName)FilterInput",
                value: .object(predicateJSON))
        }

        return document.copy(inputs: inputs)
    }
}
