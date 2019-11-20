//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension GraphQLMutation {
    init(of anyModel: AnyModel, type mutationType: GraphQLMutationType) {
        self.init(of: anyModel.instance, type: mutationType)
    }
}
