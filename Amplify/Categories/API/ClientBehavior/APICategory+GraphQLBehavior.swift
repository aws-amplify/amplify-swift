//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryGraphQLBehavior {
    public func mutate<R: Decodable>(apiName: String,
                                     document: String,
                                     variables: [String: Any]? = nil,
                                     responseType: R.Type,
                                     listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {
            plugin.mutate(apiName: apiName,
                          document: document,
                          variables: variables,
                          responseType: responseType,
                          listener: listener)
    }

    public func query<R: Decodable>(apiName: String,
                                    document: String,
                                    variables: [String: Any]? = nil,
                                    responseType: R.Type,
                                    listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {

            plugin.query(apiName: apiName,
                         document: document,
                         variables: variables,
                         responseType: responseType,
                         listener: listener)
    }
}
