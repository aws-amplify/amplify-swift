//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public enum AuthRuleDecoratorInput {
    public typealias OwnerId = String
    case subscription(GraphQLSubscriptionType, OwnerId)
    case mutation
    case query
}

// Tracking issue: https://github.com/aws-amplify/amplify-cli/issues/4182 Once this issue is resolved, the behavior and
// the interface is expected to change. Subscription operations should not need to take in any owner fields in the
// document input, similar to how the mutations operate. For now, the provisioned backend requires owner field for
// the subscription operation corresponding to the operation defined on the auth rule. For example,
// @auth(rules: [ { allow: owner, operations: [create, delete] } ])
// contains create and delete, therefore the onCreate and onDelete subscriptions require the owner field, but not the
// onUpdate subscription.

/// Decorate the document with auth related fields. For `owner` strategy, fields include:
/// * add the value of `ownerField` to the model selection set, defaults "owner" when `ownerField` is not specified
/// * owner field value for subscription document inputs for the corresponding auth rule `operation`
public struct AuthRuleDecorator: ModelBasedGraphQLDocumentDecorator {

    private let input: AuthRuleDecoratorInput

    public init(_ authRuleDecoratorInput: AuthRuleDecoratorInput) {
        self.input = authRuleDecoratorInput
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

        let ownerField = authRule.getOwnerFieldOrDefault()
        selectionSet = appendOwnerFieldToSelectionSetIfNeeded(selectionSet: selectionSet, ownerField: ownerField)

        guard case let .subscription(subscriptionType, ownerId) = input else {
            return document.copy(selectionSet: selectionSet)
        }

        let operations = authRule.getModelOperationsOrDefault()
        if isOwnerInputRequiredOnSubscription(subscriptionType, operations: operations) {
            var inputs = document.inputs
            inputs[ownerField] = GraphQLDocumentInput(type: "String!", value: .scalar(ownerId))
            return document.copy(inputs: inputs, selectionSet: selectionSet)
        }
        return document.copy(selectionSet: selectionSet)
    }

    private func isOwnerInputRequiredOnSubscription(_ subscriptionType: GraphQLSubscriptionType,
                                                    operations: [ModelOperation]) -> Bool {
        var isOwnerInputRequired = false
        switch subscriptionType {
        case .onCreate:
            if operations.contains(.create) {
                isOwnerInputRequired = true
            }
        case .onUpdate:
            if operations.contains(.update) {
                isOwnerInputRequired = true
            }
        case .onDelete:
            if operations.contains(.delete) {
                isOwnerInputRequired = true
            }
        }
        return isOwnerInputRequired
    }

    /// First finds the first `model` SelectionSet. Then, only append it when the `ownerField` does not exist.
    private func appendOwnerFieldToSelectionSetIfNeeded(selectionSet: SelectionSet,
                                                        ownerField: String) -> SelectionSet {
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
