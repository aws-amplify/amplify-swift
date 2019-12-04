//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct QueryRequestListenerResponder<R: Decodable> {

    typealias Callback = (GraphQLRequest<R>, GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R>?

    let callback: Callback

    init(callback: @escaping Callback) {
        self.callback = callback
    }
}
