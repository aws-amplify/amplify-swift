//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension GraphQLRequest {
    static func appSync<ResponseType: Decodable>(apiName: String? = nil,
                                                 document: String,
                                                 variables: [String: Any]? = nil,
                                                 responseType: ResponseType.Type,
                                                 decodePath: String? = nil,
                                                 authMode: AWSAuthorizationType? = nil,
                                                 options: GraphQLRequest<ResponseType>.Options? = nil) -> GraphQLRequest<ResponseType> {
        return GraphQLRequest<ResponseType>(apiName: apiName,
                                            document: document,
                                            variables: variables,
                                            responseType: responseType.self,
                                            decodePath: decodePath,
                                            authMode: authMode,
                                            options: options)
    }
}

