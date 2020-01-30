//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A concrete implementation of `GraphQLDocument` that represents a update mutation operation.
public class GraphQLUpdateMutation: ModelBasedGraphQLDocument {
    private let model: Model

    public init(model: Model) {
        let modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)
        self.model = model
        super.init(operationType: .mutation(.update), modelType: modelType)
    }

    public override var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        return ["input": GraphQLDocumentInput(type: "\(name.pascalCased())Input!", value: .object(model.graphQLInput))]
    }
}
