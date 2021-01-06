//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension RESTOperationRequest {
    init(request: RESTRequest, operationType: RESTOperationType) {
        self = RESTOperationRequest(apiName: request.apiName,
                                    operationType: operationType,
                                    path: request.path,
                                    headers: request.headers,
                                    queryParameters: request.queryParameters,
                                    body: request.body,
                                    options: RESTOperationRequest.Options())
    }
}
