//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// https://github.com/aws-amplify/amplify-cli/issues/4182
// If the owner authorization does not contain `.read` operation, then others can read owners data,
// do not have to apply any owner field to the subscription document input
/// Decorate the document with auth related fields such as the selection set and owner input to subscription documents
public struct AuthRuleDecorator: ModelBasedGraphQLDocumentDecorator {

    private let subscriptionType: GraphQLSubscriptionType?
    private let ownerId: String?

    public init(subscriptionType: GraphQLSubscriptionType? = nil, ownerId: String? = nil) {
        self.subscriptionType = subscriptionType
        self.ownerId = ownerId
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        let authRules = modelType.schema.authRules
        guard !authRules.isEmpty else {
            return document
        }
        var decorateDocument = document
        authRules.forEach { authRule in
            decorateDocument = decorateIfOwnerAuthStrategy(document: decorateDocument, authRule: authRule)
        }
        return decorateDocument
    }

    func decorateIfOwnerAuthStrategy(document: SingleDirectiveGraphQLDocument,
                                     authRule: AuthRule) -> SingleDirectiveGraphQLDocument {
        guard authRule.allow == .owner else {
            return document
        }

        guard var selectionSet = document.selectionSet else {
            return document
        }

        let ownerField = (authRule.ownerField != nil) ? authRule.ownerField!.stringValue : "owner"
        selectionSet = withOwnerField(selectionSet: selectionSet, ownerField: ownerField)

        guard let subscriptionType = subscriptionType else {
            return document.copy(selectionSet: selectionSet)
        }

        let operations = authRule.operations.isEmpty ? [.create, .update, .delete, .read] : authRule.operations

        var requiredOwnerInput = false
        switch subscriptionType {
        case .onCreate:
            if operations.contains(.create) {
                requiredOwnerInput = true
            }
        case .onUpdate:
            if operations.contains(.update) {
                requiredOwnerInput = true
            }
        case .onDelete:
            if operations.contains(.delete) {
                requiredOwnerInput = true
            }
        }

        if requiredOwnerInput, let ownerId = ownerId {
            var inputs = document.inputs
            inputs[ownerField] = GraphQLDocumentInput(type: "String!", value: .scalar(ownerId))
            return document.copy(inputs: inputs, selectionSet: selectionSet)
        }
        return document.copy(selectionSet: selectionSet)
    }

    /// First finds the first `model` SelectionSet. Then, only append it when the `ownerField` does not exist.
    func withOwnerField(selectionSet: SelectionSet, ownerField: String) -> SelectionSet {
        var selectionSetModel = selectionSet
        while selectionSetModel.value.fieldType != .model {
            selectionSetModel.children.forEach { selectionSet in
                if selectionSet.value.fieldType == .model {
                    selectionSetModel = selectionSet
                }
            }

        }

        let containersOwnerField =  selectionSetModel.children.contains { (field) -> Bool in
            if let fieldName = field.value.name, fieldName == ownerField {
                return true
            }
            return false
        }
        if !containersOwnerField {
            let child = SelectionSet(value: .init(name: ownerField, fieldType: .value))
            selectionSetModel.children.append(child)
        }

        return selectionSet
    }
}
