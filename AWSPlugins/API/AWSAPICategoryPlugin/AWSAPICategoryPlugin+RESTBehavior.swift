//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    func get(apiName: String,
             path: String,
             listener: APIGetOperation.EventListener?) -> APIGetOperation {
        let options = APIGetRequest.Options()
        let request = APIGetRequest(apiName: apiName,
                                    path: path,
                                    options: options)
        let operation = AWSAPIGetOperation(request: request,
                                           httpTransport: httpTransport,
                                           listener: listener)
        return operation
    }

}
