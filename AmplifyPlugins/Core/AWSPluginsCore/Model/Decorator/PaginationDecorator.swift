//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the document input with "limit" and "nextToken". Also paginates the selection set with pagination fields.
public struct PaginationDecorator: SingleDirectiveGraphQLDocumentDecorator {

    private let limit: Int?
    private let nextToken: String?

    public init(limit: Int? = nil, nextToken: String? = nil) {
        self.limit = limit
        self.nextToken = nextToken
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if let limit = limit {
            inputs["limit"] = GraphQLDocumentInput(type: "Int", value: .value(limit))
        } else {
            inputs["limit"] = GraphQLDocumentInput(type: "Int", value: .value(1_000))
        }

        if let nextToken = nextToken {
            inputs["nextToken"] = GraphQLDocumentInput(type: "String", value: .value(nextToken))
        }

        if let selectionSet = document.selectionSet {
            return document.copy(inputs: inputs,
                                 selectionSet: selectionSet.paginated)
        }

        return document.copy(inputs: inputs)
    }
}
