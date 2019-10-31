//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryGraphQLBehavior {
    public func mutate<R>(apiName: String,
                          document: String,
                          variables: [String: Any]? = nil,
                          responseType: R,
                          listener: ((AsyncEvent<Void, GraphQLResponse<R.SerializedObject>, GraphQLError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R.SerializedObject>, GraphQLError> where R: ResponseType {
            plugin.mutate(apiName: apiName,
                          document: document,
                          variables: variables,
                          responseType: responseType,
                          listener: listener)
    }

    public func query<R: ResponseType>(apiName: String,
                                       document: String,
                                       variables: [String: Any]? = nil,
                                       responseType: R,
                                       listener: ((AsyncEvent<Void, GraphQLResponse<R.SerializedObject>, GraphQLError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R.SerializedObject>, GraphQLError> {

            plugin.query(apiName: apiName,
                         document: document,
                         variables: variables,
                         responseType: responseType,
                         listener: listener)
    }
}
