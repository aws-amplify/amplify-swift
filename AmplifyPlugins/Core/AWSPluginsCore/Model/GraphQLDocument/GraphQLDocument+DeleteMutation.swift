//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLDeleteMutation {
    convenience init(of model: Model) {

        self.init(modelName: model.modelName,
                  id: model.id)
    }
}

public class GraphQLDeleteMutation: ModelBasedGraphQLDocument {

    private let id: Model.Identifier

    public init(modelName: String, id: Model.Identifier) {
        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            preconditionFailure("Model with name \(modelName) could not be found.")
        }
        self.id = id
        super.init(operationType: .mutation(.delete), modelType: modelType)
    }

    public override var inputs: [GraphQLParameterName: GraphQLDocumentInput] {
        return ["input": GraphQLDocumentInput(type: "\(name.pascalCased())Input!", value: .object(["id": id]))]
    }
}
