//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class GraphQLSyncMutation: GraphQLMutation {

    public let version: Int?

    public init(of model: Model, type mutationType: GraphQLMutationType, version: Int? = nil) {
        self.version = version
        super.init(of: model, type: mutationType)
    }

    public override var hasSyncableModels: Bool {
        return true
    }

    public override var variables: [String: Any] {

        if mutationType == .delete {
            var graphQLInput = ["id": model.id] as GraphQLInput
            if let version = version {
                graphQLInput.updateValue(version, forKey: "_version")
            }

            return [
                "input": graphQLInput
            ]
        } else {
            var graphQLInput = model.graphQLInput
            if let version = version {
                graphQLInput.updateValue(version, forKey: "_version")
            }
            return [
                "input": graphQLInput
            ]
        }
    }
}
