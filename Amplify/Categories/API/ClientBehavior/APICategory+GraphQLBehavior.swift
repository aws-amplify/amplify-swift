//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryGraphQLBehavior {

    public func graphql(apiName: String,
                        operationType: GraphQLOperationType,
                        document: String,
                        listener: GraphQLOperation.EventListener?) -> GraphQLOperation {
        plugin.graphql(apiName: apiName,
                       operationType: operationType,
                       document: document,
                       listener: listener)
    }

}
