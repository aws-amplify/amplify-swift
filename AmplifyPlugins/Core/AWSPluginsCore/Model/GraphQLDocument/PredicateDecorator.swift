//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension SingleDirectiveGraphQLDocument {
    public func withPredicate(_ predicate: QueryPredicate?, modelName: String) -> SingleDirectiveGraphQLDocument {
        if let predicate = predicate {
            return PredicateDecorator(self, queryPredicate: predicate, modelName: modelName)
        }
        return self
    }
}

// inject the predicate as a condition or a filter on the Model based GraphQL
// this decorator is a very Model/GraphQL
class PredicateDecorator: SingleDirectiveGraphQLDocument {

    private let graphQLDocument: SingleDirectiveGraphQLDocument
    private let queryPredicate: QueryPredicate
    private let modelName: String

    public init(_ graphQLDocument: SingleDirectiveGraphQLDocument,
                queryPredicate: QueryPredicate,
                modelName: String) {
        self.graphQLDocument = graphQLDocument
        self.queryPredicate = queryPredicate
        self.modelName = modelName
    }

    public var operationType: GraphQLOperationType {
        graphQLDocument.operationType
    }

    public var name: String {
        graphQLDocument.name
    }

    public var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        var inputs = graphQLDocument.inputs

        if case .mutation = graphQLDocument.operationType {
            inputs["condition"] = GraphQLDocumentInput(type: "Model\(modelName)ConditionInput",
                value: .object(queryPredicate.graphQLFilterVariables))
        } else if case .query = graphQLDocument.operationType {
            inputs["filter"] = GraphQLDocumentInput(type: "Model\(modelName)FilterInput",
                value: .object(queryPredicate.graphQLFilterVariables))
        } else {
            preconditionFailure("Cannot add predicate to subscription")
        }

        return inputs
    }

    public var selectionSetFields: [SelectionSetField] {
        return graphQLDocument.selectionSetFields
    }
}
