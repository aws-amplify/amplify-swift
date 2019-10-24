//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSAPIOperation: AmplifyOperation<APIGetRequest,
    Void,
    Data,
    APIError
    >,
APIOperation {

    static let timeout = TimeInterval(120)

    init(request: APIGetRequest,
         eventName: String,
         listener: AWSAPIOperation.EventListener?) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.get,
                   request: request,
                   listener: listener)

    }

}
