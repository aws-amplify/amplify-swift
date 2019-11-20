//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLRequest {
    /// Gets a GraphQLRequest for an `AnyModel`, erasing both the incoming and return type. The actual document created
    /// for the request will be cast to the type of the AnyModel's `instance`.
    static func mutation(of anyModel: AnyModel,
                         type: GraphQLMutationType) -> GraphQLRequest<AnyModel> {
        let document = GraphQLMutation(of: anyModel, type: type)
        return GraphQLRequest<AnyModel>(document: document.stringValue,
                                        variables: document.variables,
                                        responseType: AnyModel.self,
                                        decodePath: document.decodePath)
    }
}
