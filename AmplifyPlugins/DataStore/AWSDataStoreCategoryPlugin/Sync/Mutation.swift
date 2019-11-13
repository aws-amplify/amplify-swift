//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct Mutation<M: Model> {

    let model: M
    let event: MutationEvent

    var modelType: M.Type {
        type(of: model)
    }
}
