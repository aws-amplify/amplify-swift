//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Adds conflict resolution information onto the document based on the operation type (query or mutation)
/// All selection sets are decorated with conflict resolution fields and inputs are added based on the values that it
/// was instantiated with. If `version` is passed, the input with key "input" will contain "_version" with the `version`
/// value. If `lastSync` is passed, the input will contain new key "lastSync" with the `lastSync` value.
public struct ConflictResolutionDecorator: ModelBasedGraphQLDocumentDecorator {

    private let version: Int?
    private let lastSync: Int?

    public init(version: Int? = nil, lastSync: Int? = nil) {
        self.version = version
        self.lastSync = lastSync
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if let version = version,
            case .mutation = document.operationType,
            var input = inputs["input"],
            case var .object(value) = input.value {

            value["_version"] = version
            input.value = .object(value)
            inputs["input"] = input
        }

        if let lastSync = lastSync, case .query = document.operationType {
            inputs["lastSync"] = GraphQLDocumentInput(type: "AWSTimestamp", value: .scalar(lastSync))
        }

        if let selectionSet = document.selectionSet {
            addConflictResolution(selectionSet: selectionSet)
            return document.copy(inputs: inputs, selectionSet: selectionSet)
        }

        return document.copy(inputs: inputs)
    }

    /// Append the correct conflict resolution fields for `model` and `pagination` selection sets.
    private func addConflictResolution(selectionSet: SelectionSet) {
        switch selectionSet.value.fieldType {
        case .value, .embedded:
            break
        case .model:
            selectionSet.addChild(settingParentOf: .init(value: .init(name: "_version", fieldType: .value)))
            selectionSet.addChild(settingParentOf: .init(value: .init(name: "_deleted", fieldType: .value)))
            selectionSet.addChild(settingParentOf: .init(value: .init(name: "_lastChangedAt", fieldType: .value)))
        case .pagination:
            selectionSet.addChild(settingParentOf: .init(value: .init(name: "startedAt", fieldType: .value)))
        }

        selectionSet.children.forEach { child in
            addConflictResolution(selectionSet: child)
        }
    }
}
