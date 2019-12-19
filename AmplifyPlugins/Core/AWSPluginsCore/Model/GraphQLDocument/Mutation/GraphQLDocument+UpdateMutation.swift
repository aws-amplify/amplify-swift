//
// Copyright 2018-2019 Amazon.com,
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
    public let syncEnabledVersion: Int?

    public init(of model: Model,
                where predicate: QueryPredicate? = nil,
                syncEnabledVersion: Int? = nil) {
        self.model = model
        self.modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)
        self.predicate = predicate
        self.syncEnabledVersion = syncEnabledVersion
    }

    public var name: String {
        mutationType.rawValue + model.schema.graphQLName
    }

    public var hasSyncableModels: Bool {
        syncEnabledVersion != nil
    }

    public var stringValue: String {
        let mutationName = name.pascalCased()
        let inputName = "input"
        let inputType = "\(mutationName)Input!"

        let conditionInputName = "condition"
        let conditionInputType = "Model\(modelType.schema.graphQLName)ConditionInput"

        let document = """
        \(documentType) \(mutationName)($\(inputName): \(inputType), $\(conditionInputName): \(conditionInputType)) {
          \(name)(\(inputName): $\(inputName), \(conditionInputName): $\(conditionInputName)) {
            \(selectionSetFields.joined(separator: "\n    "))
          }
        }
        """

        return document
    }

    public var variables: [String: Any] {
        var variables = [String: Any]()
        if let condition = predicate {
            variables.updateValue(condition.graphQLFilterVariables, forKey: "condition")
        }

        var graphQLInput = model.graphQLInput
        if let version = syncEnabledVersion {
            graphQLInput.updateValue(version, forKey: "_version")
        }
        variables.updateValue(graphQLInput, forKey: "input")

        return variables
    }
}
