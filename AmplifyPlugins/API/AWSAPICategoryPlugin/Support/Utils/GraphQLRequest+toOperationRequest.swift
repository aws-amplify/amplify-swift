//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Amplify.GraphQLRequest
import struct Amplify.GraphQLOperationRequest
import enum Amplify.GraphQLOperationType

import AWSPluginsCore

extension GraphQLRequest {
    func toOperationRequest(operationType: GraphQLOperationType) -> GraphQLOperationRequest<R> {
        let awsPluginOptions = pluginOptions as? AWSPluginOptions
        return GraphQLOperationRequest<R>(apiName: apiName,
                                          operationType: operationType,
                                          document: document,
                                          variables: variables,
                                          responseType: responseType,
                                          decodePath: decodePath,
                                          options: AWSPluginOptions(authType: awsPluginOptions?.authType))
    }
}
