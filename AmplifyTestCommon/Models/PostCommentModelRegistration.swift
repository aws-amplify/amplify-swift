//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public final class PostCommentModelRegistration: AmplifyModelRegistration {
    public func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
    }

    public let version: String = "1"
}
