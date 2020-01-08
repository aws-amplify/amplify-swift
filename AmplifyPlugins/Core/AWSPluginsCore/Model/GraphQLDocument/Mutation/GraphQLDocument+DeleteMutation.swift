//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLDeleteMutation {
    convenience init(of model: Model,
                     where predicate: QueryPredicate? = nil) {

        self.init(of: model.modelName,
                  id: model.id,
                  where: predicate)
    }
}

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
public class GraphQLDeleteMutation: GraphQLDocument {

    public let documentType = GraphQLDocumentType.mutation
    public let mutationType = GraphQLMutationType.delete

    public let modelName: String
    public let modelType: Model.Type
    public let id: Model.Identifier
    public let predicate: QueryPredicate?

    public init(of modelName: String,
                id: Model.Identifier,
                where predicate: QueryPredicate? = nil) {
        self.modelName = modelName
        self.id = id
        self.predicate = predicate
        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            preconditionFailure("Model with name \(modelName) could not be found.")
        }
        self.modelType = modelType
    }

    public var name: String {
        mutationType.rawValue + modelName
    }

    public var inputTypes: String? {
        return "$input: \(name.pascalCased())Input!, $condition: Model\(modelType.schema.graphQLName)ConditionInput"
    }

    public var inputParameters: String? {
        "input: $input, condition: $condition"
    }

    public var variables: [String: Any] {
        var variables = [String: Any]()

        if let condition = predicate {
            variables.updateValue(condition.graphQLFilterVariables, forKey: "condition")
        }

        let graphQLInput = ["id": id] as [String: Any]

        variables.updateValue(graphQLInput, forKey: "input")

        return variables
    }
}
