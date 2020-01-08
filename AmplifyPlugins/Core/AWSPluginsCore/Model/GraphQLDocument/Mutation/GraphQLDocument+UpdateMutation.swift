//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLUpdateMutation {
    convenience init(of anyModel: AnyModel,
                     where predicate: QueryPredicate? = nil) {
        self.init(of: anyModel.instance, where: predicate)
    }
}

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
public class GraphQLUpdateMutation: GraphQLDocument {

    public let documentType = GraphQLDocumentType.mutation
    public let model: Model
    public let modelType: Model.Type
    public let predicate: QueryPredicate?
    public let mutationType = GraphQLMutationType.update

    public init(of model: Model,
                where predicate: QueryPredicate? = nil) {
        self.model = model
        self.modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)
        self.predicate = predicate
    }

    public var name: String {
        mutationType.rawValue + model.schema.graphQLName
    }

    public var inputTypes: String? {
        "$input: \(name.pascalCased())Input!, $condition: Model\(modelType.schema.graphQLName)ConditionInput"
    }

    public var inputParameters: String? {
        "input: $input, condition: $condition"
    }

    public var variables: [String: Any] {
        var variables = [String: Any]()
        if let condition = predicate {
            variables.updateValue(condition.graphQLFilterVariables, forKey: "condition")
        }

        let graphQLInput = model.graphQLInput
        variables.updateValue(graphQLInput, forKey: "input")

        return variables
    }
}
