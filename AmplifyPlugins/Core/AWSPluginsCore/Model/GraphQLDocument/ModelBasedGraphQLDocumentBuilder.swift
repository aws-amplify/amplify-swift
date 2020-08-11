//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Helps construct a `SingleDirectiveGraphQLDocument`. Collects instances of the decorators and applies the changes
/// on the document.
public struct ModelBasedGraphQLDocumentBuilder {
    private var decorators = [ModelBasedGraphQLDocumentDecorator]()
    private var document: SingleDirectiveGraphQLDocument
    private let schema: ModelSchema

    public init(modelName: String, operationType: GraphQLOperationType) {
        guard let modelSchema = ModelRegistry.modelSchema(from: modelName)  else {
            preconditionFailure("Missing ModelType in ModelRegistry for model name: \(modelName)")
        }

        self.init(schema: modelSchema, operationType: operationType)
    }

    public init(schema: ModelSchema, operationType: GraphQLOperationType) {
        self.schema = schema
        switch operationType {
        case .query:
            self.document = GraphQLQuery(graphQLFields: schema.graphQLFields)
        case .mutation:
            self.document = GraphQLMutation(graphQLFields: schema.graphQLFields)
        case .subscription:
            self.document = GraphQLSubscription(graphQLFields: schema.graphQLFields)
        }
    }

    public mutating func add(decorator: ModelBasedGraphQLDocumentDecorator) {
        decorators.append(decorator)
    }

    public mutating func build() -> SingleDirectiveGraphQLDocument {

        let decoratedDocument = decorators.reduce(document) { doc, decorator in
            decorator.decorate(doc, schema: self.schema)
        }

        return decoratedDocument
    }
}
