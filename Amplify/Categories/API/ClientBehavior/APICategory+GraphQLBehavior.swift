//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryGraphQLBehavior {

    public func graphql<T>(apiName: String,
                           operationType: GraphQLOperationType,
                           document: String,
                           classToCast: T.Type,
                           listener: GraphQLOperation.EventListener?) -> GraphQLOperation where T: Codable {
        plugin.graphql(apiName: apiName,
                       operationType: operationType,
                       document: document,
                       classToCast: classToCast,
                       listener: listener)
    }

}
