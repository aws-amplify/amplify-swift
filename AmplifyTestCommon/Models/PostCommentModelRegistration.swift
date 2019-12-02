//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class PostCommentModelRegistration: AmplifyModelRegistration {
    public func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: PostNoSync.self)
        ModelRegistry.register(modelType: CommentNoSync.self)
    }

  public let version: String = "1"
}
