//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    func get(apiName: String, path: String, listener: ((AsyncEvent<Void, Codable, StorageError>) -> Void)?) -> APIGetOperation {
        fatalError("Not yet implemented")
    }

}
