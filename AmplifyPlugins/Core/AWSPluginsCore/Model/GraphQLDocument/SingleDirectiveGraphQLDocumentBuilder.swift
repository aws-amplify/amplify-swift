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
public struct SingleDirectiveGraphQLDocumentBuilder {
    private var decorators = [SingleDirectiveGraphQLDocumentDecorator]()
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

    public mutating func add(decorator: SingleDirectiveGraphQLDocumentDecorator) {
        decorators.append(decorator)
    }

    public mutating func build() -> SingleDirectiveGraphQLDocument {
        decorators.forEach { decorator in
            document = decorator.decorate(document, modelType: self.modelType)
        }

        return document
    }
}
