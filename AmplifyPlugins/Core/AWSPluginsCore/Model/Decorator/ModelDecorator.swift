//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQL document with the data from an instance of the model. This is added as a single parameter
/// called "input" that can be referenced by other decorators to append additional document inputs. This decorator
/// constructs the input's type using the document name.
public struct ModelDecorator: ModelBasedGraphQLDocumentDecorator {

    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs
        inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
            value: .object(model.graphQLInput))
        return document.copy(inputs: inputs)
    }
}
