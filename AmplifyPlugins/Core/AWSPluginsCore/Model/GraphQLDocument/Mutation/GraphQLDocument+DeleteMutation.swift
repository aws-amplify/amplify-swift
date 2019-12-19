//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLDeleteMutation {
    convenience init(of model: Model,
                     where predicate: QueryPredicate? = nil,
                     syncEnabledVersion: Int? = nil) {

        self.init(of: model.modelName,
                  id: model.id,
                  where: predicate,
                  syncEnabledVersion: syncEnabledVersion)
    }
}

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
public class GraphQLDeleteMutation: GraphQLDocument {

    public let documentType = GraphQLDocumentType.mutation
    public let mutationType = GraphQLMutationType.delete

    public let modelName: String
    public let id: Model.Identifier
    public let predicate: QueryPredicate?
    public let syncEnabledVersion: Int?

    public let modelType: Model.Type

    public init(of modelName: String,
                id: Model.Identifier,
                where predicate: QueryPredicate? = nil,
                syncEnabledVersion: Int? = nil) {
        self.modelName = modelName
        self.id = id
        self.predicate = predicate
        self.syncEnabledVersion = syncEnabledVersion
        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            preconditionFailure("Model with name \(modelName) could not be found.")
        }
        self.modelType = modelType
    }

    public var name: String {
        mutationType.rawValue + modelName
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

        var graphQLInput = ["id": id] as [String: Any]
        if let version = syncEnabledVersion {
            graphQLInput.updateValue(version, forKey: "_version")
        }

        variables.updateValue(graphQLInput, forKey: "input")

        return variables
    }
}
