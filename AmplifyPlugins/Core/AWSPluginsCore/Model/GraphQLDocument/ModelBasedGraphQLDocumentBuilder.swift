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
    private let modelType: Model.Type

    public init(modelName: String, operationType: GraphQLOperationType) {
        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            preconditionFailure("Missing ModelType in ModelRegistry for model name: \(modelName)")
        }

        self.init(modelType: modelType, operationType: operationType)
    }

    public init(modelType: Model.Type, operationType: GraphQLOperationType) {
        self.modelType = modelType
        switch operationType {
        case .query:
            self.document = GraphQLQuery(modelType: modelType)
        case .mutation:
            self.document = GraphQLMutation(modelType: modelType)
        case .subscription:
            self.document = GraphQLSubscription(modelType: modelType)
        }
    }

    public mutating func add(decorator: ModelBasedGraphQLDocumentDecorator) {
        decorators.append(decorator)
    }

    public mutating func build() -> SingleDirectiveGraphQLDocument {

        let decoratedDocument = decorators.reduce(document) { doc, decorator in
            decorator.decorate(doc, modelType: self.modelType)
        }

        return decoratedDocument
    }
}
