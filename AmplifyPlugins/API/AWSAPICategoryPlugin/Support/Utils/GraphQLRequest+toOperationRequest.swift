//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension GraphQLRequest {
    func toOperationRequest(operationType: GraphQLOperationType) -> GraphQLOperationRequest<R> {
        return GraphQLOperationRequest<R>(apiName: apiName,
                                          operationType: operationType,
                                          document: document,
                                          variables: variables,
                                          responseType: responseType,
                                          decodePath: decodePath,
                                          options: GraphQLOperationRequest.Options())
    }
}
