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
    private let modelSchema: ModelSchema

    public init(modelName: String, operationType: GraphQLOperationType) {
        guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
            preconditionFailure("Missing ModelSchema in ModelRegistry for model name: \(modelName)")
        }
        self.modelSchema = modelSchema
        switch operationType {
        case .query:
            self.document = GraphQLQuery(graphQLFields: modelSchema.graphQLFields)
        case .mutation:
            self.document = GraphQLMutation(graphQLFields: modelSchema.graphQLFields)
        case .subscription:
            self.document = GraphQLSubscription(graphQLFields: modelSchema.graphQLFields)
        }
    }

    public mutating func add(decorator: ModelBasedGraphQLDocumentDecorator) {
        decorators.append(decorator)
    }

    public mutating func build() -> SingleDirectiveGraphQLDocument {

        let decoratedDocument = decorators.reduce(document) { doc, decorator in
            decorator.decorate(doc, modelSchema: self.modelSchema)
        }

        return decoratedDocument
    }
}
