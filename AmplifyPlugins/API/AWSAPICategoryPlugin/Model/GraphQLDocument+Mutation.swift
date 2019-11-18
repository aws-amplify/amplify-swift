//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Defines the type of a GraphQL mutation.
public enum GraphQLMutationType: String {
    case create
    case update
    case delete
}

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
public struct GraphQLMutation<M: Model>: GraphQLDocument {

    public let documentType: GraphQLDocumentType = .mutation
    public let modelType: M.Type
    public let mutationType: GraphQLMutationType

    public init(of modelType: M.Type, type mutationType: GraphQLMutationType) {
        self.modelType = modelType
        self.mutationType = mutationType
    }

    public var name: String {
        mutationType.rawValue + modelType.schema.graphQLName
    }

    public var stringValue: String {
        let schema = modelType.schema

        let mutationName = name
        let documentName = mutationName.prefix(1).uppercased() + mutationName.dropFirst()

        let inputName = mutationType == .delete ? "id" : "input"
        let inputType = mutationType == .delete ? "ID!" : "\(documentName)Input!"
        let fields = schema.graphQLFields.map { $0.graphQLName }

        return """
        \(documentType) \(documentName)($\(inputName): \(inputType)) {
          \(mutationName)(\(inputName): $\(inputName)) {
            \(fields.joined(separator: "\n    "))
          }
        }
        """
    }

}
