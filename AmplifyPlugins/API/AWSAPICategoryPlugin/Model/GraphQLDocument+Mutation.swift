//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Defines the type of a GraphQL mutation.
enum GraphQLMutationType: String {
    case create
    case update
    case delete
}

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
struct GraphQLMutation<M: Model>: GraphQLDocument {

    let documentType: GraphQLDocumentType = .mutation
    let modelType: M.Type
    let mutationType: GraphQLMutationType

    init(of modelType: M.Type, type mutationType: GraphQLMutationType) {
        self.modelType = modelType
        self.mutationType = mutationType
    }

    var name: String {
        mutationType.rawValue + modelType.schema.graphQLName
    }

    var stringValue: String {
        let schema = modelType.schema

        let mutationName = name
        let documentName = mutationName.prefix(1).uppercased() + mutationName.dropFirst()

        let inputName = mutationType == .delete ? "id" : "input"
        let inputType = mutationType == .delete ? "ID!" : "\(documentName)Input!"

        return """
        \(documentType) \(documentName)($\(inputName): \(inputType)) {
          \(mutationName)(\(inputName): $\(inputName)) {
            \(schema.graphQLFields.joined(separator: "\n    "))
          }
        }
        """
    }

}
