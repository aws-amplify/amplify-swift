//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    func graphql(apiName: String,
                 operationType: GraphQLOperationType,
                 document: String,
                 listener: ((AsyncEvent<Void, Codable, StorageError>) -> Void)?) -> GraphQLOperation {
        fatalError("Not yet implemented")
    }

}
