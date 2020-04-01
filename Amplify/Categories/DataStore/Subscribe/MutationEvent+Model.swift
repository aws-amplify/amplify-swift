//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension MutationEvent {

    public init(untypedModel model: Model,
                mutationType: MutationType,
                version: Int? = nil) throws {
        guard let modelType = ModelRegistry.modelType(from: model.modelName) else {
            let dataStoreError = DataStoreError.invalidModelName(model.modelName)
            throw dataStoreError
        }

        let json = try model.toJSON()
        self.init(modelId: model.id,
                  modelName: modelType.schema.name,
                  json: json,
                  mutationType: mutationType,
                  version: version)
    }

}
