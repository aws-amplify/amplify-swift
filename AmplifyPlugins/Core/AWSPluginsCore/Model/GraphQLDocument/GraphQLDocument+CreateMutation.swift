//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class GraphQLCreateMutation: ModelBasedGraphQLDocument {
    private let model: Model

    public init(model: Model) {
        let modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)
        self.model = model
        super.init(operationType: .mutation(.create), modelType: modelType)
    }

    public override var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        return ["input": GraphQLDocumentInput(type: "\(name.pascalCased())Input!", value: .object(model.graphQLInput))]
    }
}
