//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQLDocument with the value of `Model.Identifier` for a "delete" mutation or "get" query. This
/// decorate has a dependency on `DirectiveDecorator` as it constructs the input's type using the document name for
/// mutations.
public struct ModelIdDecorator: SingleDirectiveGraphQLDocumentDecorator {

    private let id: Model.Identifier

    public init(id: Model.Identifier) {
        self.id = id
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if case .mutation = document.operationType {
            inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
            value: .object(["id": id]))
        } else if case .query = document.operationType {
            inputs["id"] = GraphQLDocumentInput(type: "ID!", value: .value(id))
        }

        return document.copy(inputs: inputs)
    }
}
