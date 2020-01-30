//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// sync enabled
extension SingleDirectiveGraphQLDocument {
    public func syncEnabled(version: Int? = nil) -> SingleDirectiveGraphQLDocument {
        return SyncEnabledDecorator(self, version: version)
    }
}

// The decorator will add sync related fields to a GraphQLDocument
// `version` gets added to the input if the decorator is instantiated with a `version` value
// Sync related fields such as `_version`, `_deleted`, and `_lastChangedAt` are added to the selection set.
public class SyncEnabledDecorator: SingleDirectiveGraphQLDocument {

    private let graphQLDocument: SingleDirectiveGraphQLDocument
    private let version: Int?

    public init(_ graphQLDocument: SingleDirectiveGraphQLDocument, version: Int? = nil) {
        self.graphQLDocument = graphQLDocument
        self.version = version
    }

    public var operationType: GraphQLOperationType {
        graphQLDocument.operationType
    }

    public var name: String {
        graphQLDocument.name
    }

    public var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        var inputs = graphQLDocument.inputs

        if let version = version,
            case .mutation = graphQLDocument.operationType,
            var input = inputs["input"],
            case var .object(value) = input.value {

            value["_version"] = version
            input.value = .object(value)
            inputs["input"] = input
        }

        return inputs
    }

    public var selectionSetFields: [SelectionSetField] {

        var selectionSetFields = graphQLDocument.selectionSetFields

        if case let .query(queryType) = graphQLDocument.operationType {
            if case .list = queryType {
                // this decorator knows that it is a list query, which implies that it is constructed with
                // items and nextToken in the first level of its selection set.
                // By sync enabling a list query, inject startedAt
                selectionSetFields.append(SelectionSetField(value: "startedAt"))

                // and then sync enable the remaining fields
                if var first = selectionSetFields.first {
                    first.innerFields = first.innerFields.syncEnabled
                    selectionSetFields[0] = first
                }

                return selectionSetFields
            } else if case .sync = queryType {
                preconditionFailure("Cannot use sync enabled decorator for sync query")
            }
        }

        return selectionSetFields.syncEnabled
    }
}
